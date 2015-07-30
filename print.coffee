

pins = require './src/pins'
{MotorControl, ServoControl} = require './src/motorControl'


class TrianglePlotter
  constructor : ->
    @_x = 0
    @_y = 0
    @_stepLeft  = 0
    @_stepRight = 0


  moveTo : (point) ->
    [left, right] = @_pointToSteps(point)
    @_plotLine(@_stepLeft, left, @_stepRight, right)
    [@_stepLeft, @_stepRight] = [left, right]
    [@_x, @_y] = point

  _plotLine : (x0, x1, y0, y1) ->
    dx = x1 - x0
    dy = y1 - y0

    if x1 is x0
      @_plotVertical(y0, y1)
    if y1 is y0
      @_plotHorizontal(x0, x1)

    errorIncrement = Math.abs((y1 - y0) / (x1 - x0))
    yIncrement = if y1 > y0 then 1 else -1
    y = y0

    error = 0

    for x in [x0..x1]
     @plotter.stepX()
     error += errorIncrement
     while error >= 0.5
       y += yIncrement
       @plotter.stepY()
       error -= 1.0

    return

  _plot2 : (left, right, delay) ->
    swapSteps = Math.abs(rightSteps) > Math.abs(leftSteps)

    leftSteps = Math.abs(leftSteps)
    rightSteps = Math.abs(rightSteps)  
    
    error = leftSteps / 2
    for left in [0...leftSteps]
      stepRight  = Direction.NONE
      error     -= rightSteps
      if (error < 0)
        stepRight = rightMotorDirection
        error += leftSteps
      
      swapSteps
        stepMotors(stepRight, leftMotorDirection, delayInMicroSeconds)
      else
        stepMotors(leftMotorDirection, stepRight, delayInMicroSeconds)



class LinePrinter
  constructor : ->
    @left  = new MotorControl(pins.motors.left)
    @right = new MotorControl(pins.motors.left)
    @plotter = new TrianglePlotter()
    #@pen   = new ServoControl(pins.pen)

  printLines : (shapes) ->
    @moveTo(@plotter.home)
    #@plotter.reset()
    for lines in shapes
      for line in lines
        for point, i in line
          # if i is 1 then @pen.down()
          @moveTo(point)
        #@pen.up()

    @moveTo(@plotter.home)
    return

  moveTo : (point) ->
    steps = @plotter.stepsTo(point)


new MotorControl(require('./pins').motors.left).step(100, false)