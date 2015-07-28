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
        when 'A'
          # TODO handle nasty arc segments
          curves = arc(segLast[0], segLast[1], seg.data[0], seg.data[1], radians(seg.data[2]), seg.data[3], seg.data[4], seg.data[5], seg.data[6])
          offset = 0
          # console.log segLast, curves
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
          # TODO Throw error. We support only SVG 1.1
          # console.log 'UNKNOWN SEGMENT', seg

      instLast = seg.instruction

    if line? then @lines.push line
    return

# MIT License
#
# Copyright © 2008-2012 Dmitry Baranovskiy (http://raphaeljs.com)
# Copyright © 2008-2012 Sencha Labs (http://sencha.com)
#
# https://github.com/DmitryBaranovskiy/raphael/blob/master/raphael.js#L2216
# http://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes
arc = (x1, y1, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2, recursive) ->
  if (!recursive)
    xy = rotate(x1, y1, -angle)
    x1 = xy.x
    y1 = xy.y
    xy = rotate(x2, y2, -angle)
    x2 = xy.x
    y2 = xy.y
    x  = (x1 - x2) / 2
    y  = (y1 - y2) / 2
    h  = (x * x) / (rx * rx) + (y * y) / (ry * ry)

    if (h > 1)
      h = Math.sqrt(h)
      rx = h * rx
      ry = h * ry

    rx2 = rx * rx
    ry2 = ry * ry
    sign = if large_arc_flag is sweep_flag then -1 else 1
    k = sign * Math.sqrt(Math.abs((rx2 * ry2 - rx2 * y * y - ry2 * x * x) / (rx2 * y * y + ry2 * x * x)))
    if (k is Infinity) then k = 1 # neutralize
    cx = k * rx * y / ry + (x1 + x2) / 2
    cy = k * -ry * x / rx + (y1 + y2) / 2
    f1 = Math.asin(((y1 - cy) / ry).toFixed(9))
    f2 = Math.asin(((y2 - cy) / ry).toFixed(9))

    f1 = if x1 < cx then Math.PI - f1 else f1
    f2 = if x2 < cx then Math.PI - f2 else f2
    if (f1 < 0) then f1 = Math.PI * 2 + f1
    if (f2 < 0) then f2 = Math.PI * 2 + f2
    if (sweep_flag && f1 > f2) then f1 = f1 - Math.PI * 2
    if (!sweep_flag && f2 > f1) then f2 = f2 - Math.PI * 2

  else
    f1 = recursive[0]
    f2 = recursive[1]
    cx = recursive[2]
    cy = recursive[3]


  ###

  df = f2 - f1
  if (Math.abs(df) > _120)
    f2old = f2
    x2old = x2
    y2old = y2
    f2    = f1 + _120 * (if (sweep_flag && f2 > f1) then 1 else -1)
    x2    = cx + rx * Math.cos(f2)
    y2    = cy + ry * Math.sin(f2)
    res   = arc(x2, y2, rx, ry, angle, 0, sweep_flag, x2old, y2old, [f2, f2old, cx, cy])

  df = f2 - f1
  c1 = Math.cos(f1)
  s1 = Math.sin(f1)
  c2 = Math.cos(f2)
  s2 = Math.sin(f2)
  t  = Math.tan(df / 4)
  hx = 4 / 3 * rx * t
  hy = 4 / 3 * ry * t
  m1 = [x1, y1]
  m2 = [x1 + hx * s1, y1 - hy * c1]
  m3 = [x2 + hx * s2, y2 - hy * c2]
  m4 = [x2, y2]
  m2[0] = 2 * m1[0] - m2[0]
  m2[1] = 2 * m1[1] - m2[1]

  if (recursive) then return [m2, m3, m4].concat(res)

  res = [m2, m3, m4].concat(res)
  newres = []
  i = 0
  while i < res.length
    newres[i] = if (i % 2) then rotate(res[i - 1], res[i], angle).y else rotate(res[i], res[i + 1], angle).x
    i += 1
  return newres

  ###
  # greater than 120 degrees requires multiple segments
  if (Math.abs(f2 - f1) > _120)
    f2old = f2
    x2old = x2
    y2old = y2
    f2    = f1 + _120 * (if (sweep_flag && f2 > f1) then 1 else -1)
    x2    = cx + rx * Math.cos(f2)
    y2    = cy + ry * Math.sin(f2)
    res   = arc(x2, y2, rx, ry, angle, 0, sweep_flag, x2old, y2old, [f2, f2old, cx, cy])

  t = Math.tan((f2 - f1) / 4)
  hx = 4 / 3 * rx * t
  hy = 4 / 3 * ry * t
  curve = [
    2 * x1 - (x1 + hx * Math.sin(f1)),
    2 * y1 - (y1 - hy * Math.cos(f1)),
    x2 + hx * Math.sin(f2),
    y2 - hy * Math.cos(f2),
    x2,
    y2
  ]

  if (res) then curve = curve.concat(res)
  if (recursive) then return curve

  i = 0
  while i < curve.length
    rot = rotate(curve[i], curve[i+1], angle)
    curve[i] = rot.x
    curve[i+1] = rot.y
    i += 2
  return curve

rotate = (x, y, rad) ->
  return {
    x : x * Math.cos(rad) - y * Math.sin(rad)
    y : x * Math.sin(rad) + y * Math.cos(rad)
  }

radians = (degress) ->
  return degress * (Math.PI / 180)

_120 = radians(120)

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
