module.exports = {
  motors :
    left :
      step       : 24
      direction  : 25
      enable     : 23
      periodMsec : 125
      invert     : false
    right :
      step       : 27
      direction  : 22
      enable     : 17
      periodMsec : 125
      invert     : true
  pen :
    power        : 18
    downMsec     : 250
    upMsec       : 250
    downPosition : 30
    upPosition   : 50
 }

###
  leftMotorStepPinNumber                : 24
  leftMotorDirectionPinNumber           : 25
  leftMotorEnablePinNumber              : 23
  leftMotorInvertDirection              : false
  leftMotorMinStepPeriodInMicroseconds  : 125
  
  rightMotorStepPinNumber               : 27
  rightMotorDirectionPinNumber          : 22
  rightMotorEnablePinNumber             : 17
  rightMotorInvertDirection             : true
  rightMotorMinStepPeriodInMicroseconds : 125
  
  penPinNumber                          : 18
  penDownPeriodInMilliseconds           : 250
  penUpPeriodInMilliseconds             : 250
  penDownPosition                       : 30
  penUpPosition                         : 50
###