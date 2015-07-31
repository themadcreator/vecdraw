keypress = require 'keypress'
keypress(process.stdin)


step = (left, right) ->
  return console.log 'step', left, right
  if left isnt 0 then leftMotor.step(invert = left < 0)
  if right isnt 0 then rightMotor.step(invert = right < 0)

process.stdin.on 'keypress', (ch, key) ->
  if key and key.ctrl and key.name is 'c' then process.exit()
  switch key.name
    when 'left' then step(-1, 1)
    when 'right' then  step(1, -1)
    when 'down' then step(1, 1)
    when 'up' then step(-1, -1)

process.stdin.setRawMode(true)
process.stdin.resume()