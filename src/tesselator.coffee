bezier           = require 'adaptive-bezier-curve'
quadratic        = require 'adaptive-quadratic-curve'
arcToCubicCurves = require './arcToCubicCurves'

class Tesselator
  constructor : (@_tesselationScale = 1.0) ->

  tesselateCurves : (data) ->
    lines       = []
    line        = null
    segStart    = null
    segLast     = null
    instLast    = null
    bezierPoint = null
    quadPoint   = null

    tesselateCubic = (startPoint, controlPoint1, controlPoint2, endPoint) ->
      tesselated  = bezier.apply(bezier, [startPoint, controlPoint1, controlPoint2, endPoint, @_tesselationScale])
      line        = line.concat(tesselated.slice(1))
      bezierPoint = controlPoint2
      segLast     = endPoint

    tesselateQuadratic = (startPoint, controlPoint1, endPoint) ->
      tesselated = quadratic.apply(quadratic, [startPoint, controlPoint1, endPoint, @_tesselationScale])
      line       = line.concat(tesselated.slice(1))
      quadPoint  = controlPoint1
      segLast    = endPoint

    for seg, i in data
      switch seg.instruction
        when 'M'
          if line? then lines.push line
          line = [seg.data]
          segStart = segLast = seg.data
        when 'z'
          line.push segLast = segStart
        when 'L'
          line.push segLast = seg.data
        when 'V'
          line.push segLast = [segLast[0], seg.data[0]]
        when 'H'
          line.push segLast = [seg.data[0], segLast[1]]
        when 'C'
          startPoint    = segLast
          controlPoint1 = [seg.data[0], seg.data[1]]
          controlPoint2 = [seg.data[2], seg.data[3]]
          endPoint      = [seg.data[4], seg.data[5]]
          tesselateCubic(startPoint, controlPoint1, controlPoint2, endPoint)
        when 'Q'
          startPoint    = segLast
          controlPoint1 = [seg.data[0], seg.data[1]]
          endPoint      = [seg.data[2], seg.data[3]]
          tesselateQuadratic(startPoint, controlPoint1, endPoint)
        when 'S'
          startPoint    = segLast
          controlPoint1 = segLast
          if instLast is 'C' or instLast is 'S'
            # Reflect previous control point
            controlPoint1 = [
              2 * segLast[0] - bezierPoint[0]
              2 * segLast[1] - bezierPoint[1]
            ]
          controlPoint2 = [seg.data[0], seg.data[1]]
          endPoint      = [seg.data[2], seg.data[3]]
          tesselateCubic(startPoint, controlPoint1, controlPoint2, endPoint)
        when 'T'
          startPoint    = segLast
          controlPoint1 = segLast
          if instLast is 'Q' or instLast is 'T'
            # Reflect previous control point
            controlPoint1 = [
              2 * segLast[0] - quadPoint[0]
              2 * segLast[1] - quadPoint[1]
            ]
          endPoint      = [seg.data[0], seg.data[1]]
          tesselateQuadratic(startPoint, controlPoint1, endPoint)
        when 'A'
          curves = arcToCubicCurves(
            segLast[0],  segLast[1]
            seg.data[0], seg.data[1]
            seg.data[2], seg.data[3], seg.data[4]
            seg.data[5], seg.data[6]
          )
          offset = 0
          while curves.length > offset
            arcSegment    = curves.slice(offset, offset + 6)
            startPoint    = segLast
            controlPoint1 = [arcSegment[0], arcSegment[1]]
            controlPoint2 = [arcSegment[2], arcSegment[3]]
            endPoint      = [arcSegment[4], arcSegment[5]]
            tesselateCubic(startPoint, controlPoint1, controlPoint2, endPoint)
            offset += 6
          segLast = [seg.data[5], seg.data[6]]
        else
          # Swallow error for best effort conversion. Useful for debugging
          # throw new Error("Unsupported path command '#{seg.instruction}'. Only SVG 1.1 path commands supported.")

      instLast = seg.instruction

    # Complete final segment
    if line? then lines.push line

    return lines

module.exports = {Tesselator}