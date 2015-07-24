

class HrTimer
  constructor : (@_callback) ->
    @avg  = 0
    @msec = 0.0
    @_start = process.hrtime()

  start : ->
    @_running = true
    @_tick()
    return @

  stop : ->
    @_running = false
    return @

  _tick : =>
    process.nextTick =>
      diff = process.hrtime(start)
      @_record(diff[0] * 1e9 + diff[1])
      if @_running
        @_callback()
        setTimeout(@_tick, 1)

  _record : (v) ->
    @msec += (v * 1e-6)
    return @avg = v * 1e-2 + @avg * (1 - 1e-2)


class HrMsec
  constructor : () ->
    @_start = process.hrtime()

  msec : ->
    diff = process.hrtime(@_start)
    return diff[0] * 1e3 + diff[1] * 1e-6

class PriorityQueue
  constructor : (@_prioritizer) ->
    @_prioritizer ?= ((v) -> v)
    @_heap = [null]

  push : (val) -> 
    @bubble(@_heap.push(val) - 1)
    return

  peek : ->
    return @_heap[1]

  pop : ->
    return undefined unless @_heap.length > 1
    if @_heap.length is 2
      return @_heap.pop()
    else 
      top = @_heap[1]
      @_heap[1] = @_heap.pop()
      @sink(1)
      return top

  bubble : (i) ->
    while i > 1
      parent = i >> 1
      break if @isHigherPriority(i, parent)
      @swap(i, parent)
      i = parent
    return

  sink : (i) ->
    while (i * 2) < @_heap.length
      right = i * 2 + 1
      left  = i * 2
      child = if right >= @_heap.length or not @isHigherPriority(left, right) then left else right
      break if @isHigherPriority(child, i)
      @swap(i, child)
      i = child
    return

  swap : (i, j) ->
    tmp = @_heap[i]
    @_heap[i] = @_heap[j]
    @_heap[j] = tmp
    return

  isHigherPriority : (i, j) ->
    return @_prioritizer(@_heap[i], i) < @_prioritizer(@_heap[j], j)


class TimedTaskQueue
  constructor : ->
    @_queue = new PriorityQueue((v) -> -1*v.msec)
    @_timer = new HrMsec()
    @tick()

  delay : (delay, task) ->
    msec = @_timer.msec() + delay
    @_queue.push {msec, delay, task}

  tick : =>
    now = @_timer.msec()
    while (next = @_queue.peek())?
      break if next.msec > now
      {task} = @_queue.pop()
      task()
    setImmediate(@tick)
    return

fastgpio = require 'fastgpio'

class Pins
  @init : (pins) ->
    for pin in pins
      fastgpio.prepareGPIO(pin)
    return new Pins()

  set : (pin, value = true) ->
    if value then fastgpio.set(pin)
    else fastgpio.unset(pin)
    return


class MotorControl
  constructor : (@motor) ->
    @_queue = new TimedTaskQueue()
    @_pins  = Pins.init([
      @motor.enable
      @motor.direction
      @motor.step
    ])

  step : (n) ->
    return if n <= 0
    console.log 'step', n
    # @_queue.delayAfterLast @motor.delay, =>
    @_pins.set(@motor.direction, true isnt @motor.invert)
    @_pins.set(@motor.step, true)
    @_pins.set(@motor.step, false)
    setTimeout((=> @step(n - 1)), 200)




# q = new TimedTaskQueue()
# q.delay 3000, -> console.log '.'
# q.delay 1000, -> console.log 'hello'
# q.delay 2000, -> console.log 'world'
new MotorControl(require('./pins').motors.left).step(10)

