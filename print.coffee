
pins = require './src/pins'
{MotorControl, ServoControl} = require './src/motorControl'



class TrianglePlotter

  constructor : ->
    @_left  = 0
    @_right = 0
    @_stepDelay = 0
    # @_leftMotor  = new MotorControl(pins.motors.left)
    # @_rightMotor = new MotorControl(pins.motors.left)

  moveToHome : (job) ->
    @_moveToSteps(job, 0, 0)

  moveTo : (job, point) ->
    [left, right] = @_pointToSteps(point)
    @_moveToSteps(job, left, right)
    return

  _moveToSteps : (job, left, right) ->
    dL = left - @_left
    dR = right - @_right

    if dL is 0
      direction = if dR > 0 then 1 else -1
      for r in [0...dR] then job.push @_stepDelay, => @_step(0, direction)
    else if dR is 0
      direction = if dL > 0 then 1 else -1
      for l in [0...dL] then job.push @_stepDelay, => @_step(direction, 0)
    else
      @_bresenhamSteps(job, dL, dR)

    @_left = left
    @_right = right

  _bresenhamSteps : (job, dL, dR) ->
    errorIncrement = Math.abs(dR / dL)
    lIncrement     = if dL > 0 then 1 else -1
    rIncrement     = if dR > 0 then 1 else -1

    error = 0
    while dL isnt 0
      dL -= lIncrement
      job.push @_stepDelay, => @_step(lIncrement, 0)
      error += errorIncrement
      while error >= 0.5
        job.push @_stepDelay, => @_step(0, rIncrement)
        error -= 1.0
    return


  _step : (left, right) ->
    # console.log 'stepping', left, right
    return
    if left  then @_leftMotor.step(left)
    if right then @_rightMotor.step(right)
    return


  _pointToSteps : (point) ->
    # config value
    base               = 250 # mm
    homeLeftLength     = 100 # mm
    homeRightLength    = 100 # mm
    stepsPerMillimeter = 10.0

    lx = (base/2.0) + point[0]
    rx = base - point[0]
    y  = point[1]

    leftLength  = Math.sqrt((lx * lx) + (y * y))
    rightLength = Math.sqrt((rx * rx) + (y * y))
    leftSteps   = Math.round((leftLength - homeLeftLength) * stepsPerMillimeter)
    rightSteps  = Math.round((rightLength - homeRightLength) * stepsPerMillimeter)
    return [leftSteps, rightSteps]

  # _plotLine : (x0, x1, y0, y1) ->
  #   dx = x1 - x0
  #   dy = y1 - y0

  #   errorIncrement = Math.abs((y1 - y0) / (x1 - x0))
  #   yIncrement = if y1 > y0 then 1 else -1
  #   y = y0

  #   error = 0
  #   for x in [x0..x1]

  #    @plotter.stepX()
  #    error += errorIncrement
  #    while error >= 0.5
  #      y += yIncrement
  #      @plotter.stepY()
  #      error -= 1.0

  #   return

  # _plot2 : (left, right, delay) ->
  #   swapSteps = Math.abs(rightSteps) > Math.abs(leftSteps)

  #   leftSteps = Math.abs(leftSteps)
  #   rightSteps = Math.abs(rightSteps)

  #   error = leftSteps / 2
  #   for left in [0...leftSteps]
  #     stepRight  = Direction.NONE
  #     error     -= rightSteps
  #     if (error < 0)
  #       stepRight = rightMotorDirection
  #       error += leftSteps

  #     swapSteps
  #       stepMotors(stepRight, leftMotorDirection, delayInMicroSeconds)
  #     else
  #       stepMotors(leftMotorDirection, stepRight, delayInMicroSeconds)


class HrMsec
  constructor : () ->
    @_start = process.hrtime()

  msec : ->
    diff = process.hrtime(@_start)
    return diff[0] * 1e3 + diff[1] * 1e-6


class TimedTaskQueue
  constructor : ->
    @_queue = []
    @_timer = new HrMsec()
    @_running = false

  push : (delay, task) ->
    @_queue.push {delay, task}

  start : ->
    @_lastTaskMsec = @_timer.msec()
    @_running = true
    @_tick()

  pause : ->
    @_running = false

  stop : ->
    @_running = false

  _tick : =>
    return unless @_running

    # maybe run next task
    next = @_queue[0]
    if next? and next.delay <= (@_timer.msec() - @_lastTaskMsec)
      @_queue.shift()
      next.task()
      @_lastTaskMsec = @_timer.msec()

    setImmediate(@_tick)
    return


class PenControl
  constructor : ->
    #@servo = new ServoControl(pins.pen)

  up : (job) ->
    job.push 200, -> console.log 'pen UP'

  down : (job) ->
    job.push 200, -> console.log 'pen DOWN'


class LinePrinter
  constructor : ->
    @plotter = new TrianglePlotter()
    @pen     = new PenControl()

  createPrintJob : (shapes) ->
    job = new TimedTaskQueue()
    @pen.up(job)
    @plotter.moveToHome(job)
    for lines in shapes
      for line in lines
        for point, i in line
          if i is 1 then @pen.down(job)
          @plotter.moveTo(job, point)
       @pen.up(job)
    @plotter.moveToHome(job)
    console.log 'job created'
    return job


fileName  = process.argv[2] ? './test.svg'
svgTest   = require('fs').readFileSync(fileName, 'utf-8')
tesselate = require './src/tesselate/tesselate'
tesselate(svgTest, 3.0).then (shapes) ->
  job = new LinePrinter().createPrintJob(shapes)
  job.start()



