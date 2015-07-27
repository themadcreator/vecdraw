Promise         = require 'bluebird'
svg2js          = require 'svgo/lib/svgo/svg2js'
plugins         = require 'svgo/lib/svgo/plugins'
pathUtils       = require 'svgo/plugins/_path'

convertShapeToPath = require 'svgo/plugins/convertShapeToPath'
convertPathData    = require 'svgo/plugins/convertPathData'

bezier    = require 'adaptive-bezier-curve'
quadratic = require 'adaptive-quadratic-curve'

class Tesselator
  type   : 'perItem'
  active : true

  constructor : (@_tesslationScale = 1.0)->
    @lines = []

  fn : (item) =>
    if item.isElem(['path']) and item.hasAttr('d')
      @tesselateCurves pathUtils.relative2absolute(item.pathJS)
    return

  tesselateCurves : (data) ->
    line        = null
    segStart    = null
    segLast     = null
    instLast    = null
    bezierPoint = null
    quadPoint   = null

    tesselateCubic = (startPoint, controlPoint1, controlPoint2, endPoint) ->
      tesselated  = bezier.apply(bezier, [startPoint, controlPoint1, controlPoint2, endPoint, @_tesslationScale])
      line        = line.concat(tesselated.slice(1))
      bezierPoint = controlPoint2
      segLast     = endPoint

    tesselateQuadratic = (startPoint, controlPoint1, endPoint) ->
      tesselated = quadratic.apply(quadratic, [startPoint, controlPoint1, endPoint, @_tesslationScale])
      line       = line.concat(tesselated.slice(1))
      quadPoint  = controlPoint1
      segLast    = endPoint

    for seg, i in data
      switch seg.instruction
        when 'M'
          if line? then @lines.push line
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
          controlPoint1 = segLast.slice()
          if instLast is 'C' or instLast is 'S'
            # Reflect previous control point
            controlPoint1[0] += controlPoint1[0] - bezierPoint[0]
            controlPoint1[1] += controlPoint1[1] - bezierPoint[1]
          controlPoint2 = [seg.data[0], seg.data[1]]
          endPoint      = [seg.data[2], seg.data[3]]
          tesselateCubic(startPoint, controlPoint1, controlPoint2, endPoint)
        when 'T'
          startPoint    = segLast
          controlPoint1 = segLast.slice()
          if instLast is 'Q' or instLast is 'T'
            # Reflect previous control point
            controlPoint1[0] += controlPoint1[0] - quadPoint[0]
            controlPoint1[1] += controlPoint1[1] - quadPoint[1]
          endPoint      = [seg.data[0], seg.data[1]]
          tesselateQuadratic(startPoint, controlPoint1, endPoint)
        else
          console.log 'UNKNOWN SEGMENT', seg

      instLast = seg.instruction

    if line? then @lines.push line
    return


module.exports = tesselate = (svgString, scale) ->
  new Promise((res, rej) -> svg2js(svgString, res)).then((items) ->
    tesselator = new Tesselator(scale)
    plugins(items, [[
      convertShapeToPath
      convertPathData
      tesselator
    ]])
    return tesselator.lines
  )
