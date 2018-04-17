context('predictCurve()')

## Input and expected data
input_fittedCurve         <- list(amplitude=275371.05624872464, center=3382.577, sigma=0.079046969170787212, gamma=0.0011476465885767637, fitStatus=2, curveModel="skewedGaussian")
class(input_fittedCurve)  <- 'peakPantheR_curveFit'

test_that('predict skewedGaussian', {
  # Input and expected results
  expected_yy       <- c(144775.46166229225, 172311.83979336367, 203679.12689962034, 239106.17013123489, 278772.24649487651, 322793.25417857931, 371207.91762216028, 423964.61459145992, 480909.49820362381, 541776.62232761492, 606180.77835683641, 673613.70995195745, 743444.28717106476, 814923.09240968002, 887191.70086404856, 959296.73416252714, 1030208.53685491032, 1098844.08378137415, 1164093.48614708940, 1224849.24068383407, 1280037.17486850498, 1328647.89590498898, 1369767.46385265631, 1402605.98833844182, 1426522.89799036412, 1441047.75167618738, 1445895.64560532128, 1440976.51057141041, 1426397.87535290653, 1402460.97884212993, 1369650.42636107188, 1328617.88595455838, 1280160.59031850239, 1225195.63379432051, 1164731.21929325885, 1099836.10904854513, 1031608.56231394515, 961146.00383406121, 889516.56481762114, 817733.48274442134, 746733.15001271770, 677357.37839575706, 610340.21142570744, 546299.38465109165, 485732.31731467048, 429016.32927684934, 376412.62212457461, 328073.44847945421, 284051.82060390856, 244313.07768557940, 208747.63736980065)
  
  result_projection <- predictCurve(fittedCurve=input_fittedCurve, x=seq(3360,3410))
  
  # Check results
  expect_equal(result_projection, expected_yy)
})

test_that('raises error()', {
  # fittedCurve is not a peakPantheR_curveFit
  expect_error(predictCurve(fittedCurve='not a peakPantheR_curveFit', x=numeric()), 'Error: "fittedCurve" must be a peakPantheR_curveFit!', fixed=TRUE)
  
  # fittedCurve is not a known model
  unknown_model         <- list(curveModel='not kown')
  class(unknown_model)  <- 'peakPantheR_curveFit'
  expect_error(predictCurve(fittedCurve=unknown_model, x=numeric()), 'Error: "fittedCurve$curveModel" must be one of: skewedGaussian', fixed=TRUE) 
})