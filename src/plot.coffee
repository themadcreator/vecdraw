line = (x0, x1, y0, y1, plot) ->
  # Assume deltax != 0 (line is not vertical),

  # note that this division needs to be done in a way that preserves the fractional part
  errorIncrement = Math.abs((y1 - y0) / (x1 - x0))
  yIncrement = if y1 > y0 then 1 else -1
  y = y0

  error = 0
  for x in [x0..x1]
   plot(x, y)
   error += errorIncrement
   while error >= 0.5
     y += yIncrement
     plot(x, y)
     error -= 1.0

  return