gdd_to_nuptake <- function(GDD) {
  
  lme.1_coefficients_fixed_3 = -0.00009361
  lme.1_coefficients_fixed_2 = 0.2460964
  lme.1_coefficients_fixed_1 = -72.67577
  YMin_DD = 400
  YMax_DD = 1315
  Ymin_N = 12.109
  Ymax_N = 89.06566
  
  m1_fitted <- function(X_Val, a, b, c)
  {
    a*(X_Val^2) + b*X_Val + c
  }
  

  ifelse(GDD<250, GDD*0,
         ifelse(GDD>=250 & GDD < YMin_DD, 
                ((0.001)*(GDD-250) + (GDD-250)^2*(Ymin_N-((0.001)*150))/(150^2)),
                ifelse(GDD>=YMin_DD & GDD < YMax_DD,
                       ((m1_fitted(GDD, lme.1_coefficients_fixed_3, lme.1_coefficients_fixed_2, lme.1_coefficients_fixed_1))/Ymax_N)*100,
                       100)))
}
