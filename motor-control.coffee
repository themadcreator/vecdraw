

class HrTimer

  constructor : ->
    @_avg = 0
    @_samples = 1

  upTime : =>
    start = process.hrtime()
    process.nextTick =>
      diff = process.hrtime(time)
      nsec = diff[0] * 1e9 + diff[1]
      @avg(nsec)
      process.nextTick(@upTime)


  avg : (v) ->
    @_samples += 1
    if @_samples % 1000 is 0 then console.log @_avg
    return @_avg = v * 1e-2 + @_avg * (1 - 1e-2)





class MotorControl
  constructor : (@motor) ->

  step : ->


new HrTimer().upTime()