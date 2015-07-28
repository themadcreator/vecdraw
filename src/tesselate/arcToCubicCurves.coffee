# MIT License
#
# Fixes, refactors and coffeescript conversion.
# Copyright © 2015 TheMadCreator (https://github.com/themadcreator)
#
# Original code from Raphael.js.
#
# Copyright © 2008-2012 Dmitry Baranovskiy (http://raphaeljs.com)
# Copyright © 2008-2012 Sencha Labs (http://sencha.com)
#
# https://github.com/DmitryBaranovskiy/raphael/blob/master/raphael.js#L2216
# http:www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes

RADIANS_120 = (2.0 / 3.0 * Math.PI)
radians     = (degress) -> degress * (Math.PI / 180.0)
rotate      = (x, y, rad) -> [
    x * Math.cos(rad) - y * Math.sin(rad)
    x * Math.sin(rad) + y * Math.cos(rad)
  ]

###
Accepts that arguments of an SVG 1.1 Arc path command and returns an array
containing the control points of a cubic bezier curve.

The length of the array will be 6*N where N is an integer >= 1.

(see http://www.w3.org/TR/SVG/paths.html#PathDataEllipticalArcCommands)
###
arcToCubicCurves = (x1, y1, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2, recursive) ->
  rangle = radians(angle)

  if not recursive
    [x1, y1] = rotate(x1, y1, -rangle)
    [x2, y2] = rotate(x2, y2, -rangle)
    x = (x1 - x2) / 2
    y = (y1 - y2) / 2
    h = (x * x) / (rx * rx) + (y * y) / (ry * ry)

    if h > 1
      h  = Math.sqrt(h)
      rx = h * rx
      ry = h * ry

    rx2  = rx * rx
    ry2  = ry * ry
    sign = if large_arc_flag is sweep_flag then -1 else 1
    k    = Math.sqrt(Math.abs((rx2 * ry2 - rx2 * y * y - ry2 * x * x) / (rx2 * y * y + ry2 * x * x)))
    if k is Infinity then k = 1 # Neutralize division by zero
    k  = k * sign
    cx = k * rx * y / ry + (x1 + x2) / 2
    cy = k * -ry * x / rx + (y1 + y2) / 2
    f1 = Math.asin(((y1 - cy) / ry).toFixed(9))
    f2 = Math.asin(((y2 - cy) / ry).toFixed(9))

    f1 = if x1 < cx then Math.PI - f1 else f1
    f2 = if x2 < cx then Math.PI - f2 else f2
    if f1 < 0 then f1 = Math.PI * 2 + f1
    if f2 < 0 then f2 = Math.PI * 2 + f2
    if sweep_flag and f1 > f2 then f1 = f1 - Math.PI * 2
    if !sweep_flag and f2 > f1 then f2 = f2 - Math.PI * 2

  else
    f1 = recursive[0]
    f2 = recursive[1]
    cx = recursive[2]
    cy = recursive[3]

  # Arcs greater than 120 degrees require multiple segments
  if Math.abs(f2 - f1) > RADIANS_120
    f2old      = f2
    x2old      = x2
    y2old      = y2
    f2         = f1 + RADIANS_120 * (if (sweep_flag && f2 > f1) then 1 else -1)
    x2         = cx + rx * Math.cos(f2)
    y2         = cy + ry * Math.sin(f2)
    childCurve = arcToCubicCurves(x2, y2, rx, ry, angle, 0, sweep_flag, x2old, y2old, [f2, f2old, cx, cy])

  t  = Math.tan((f2 - f1) / 4)
  hx = 4 / 3 * rx * t
  hy = 4 / 3 * ry * t
  mx = x1 + hx * Math.sin(f1)
  my = y1 - hy * Math.cos(f1)

  curve = [
    # control point 1
    2 * x1 - mx
    2 * y1 - my
    # control point 2
    x2 + hx * Math.sin(f2)
    y2 - hy * Math.cos(f2)
    # end point
    x2
    y2
  ]

  # Attach child curve
  if childCurve then curve = curve.concat(childCurve)

  # Return recursive value
  if recursive then return curve

  # Rotate curve points by angle
  i = 0
  while i < curve.length
    xy           = rotate(curve[i], curve[i + 1], rangle)
    curve[i]     = xy[0]
    curve[i + 1] = xy[1]
    i += 2
  return curve

module.exports = arcToCubicCurves
