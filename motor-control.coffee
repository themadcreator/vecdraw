

class HrTimer

  constructor : ->
    @_avg = 0
    @_samples = 1

  upTime : =>
    start = process.hrtime()
    process.nextTick =>
      diff = process.hrtime(start)
      nsec = diff[0] * 1e9 + diff[1]
      @avg(nsec)
      setImmediate(@upTime)

  avg : (v) ->
    @_samples += 1
    console.log Math.round(@_avg * 1e-6) + ' ' + v
    return @_avg = v * 1e-2 + @_avg * (1 - 1e-2)

class MotorControl
  constructor : (@motor) ->

  step : ->


new HrTimer().upTime()