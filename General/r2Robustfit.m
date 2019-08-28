function r2 = r2Robustfit(x,b_rob,stats_rob)
% r2 = r2Robustfit(x,brobfit,statrobfit)
% 
% This function computes the r^2 value of from the coefficients 
% and statistics of the robust regression robustfit in matlab. 
% 
% Inputs: 
%   - x:            the first argument on which the regression is computed (x-axis)
%   - b_rob:        the 2x1 vector of coefficient estimates from robust regression
%   - stats_rob:    the statistical output from robustfit function. 
% 
% The R^2 is calculated based on 
% https://fr.mathworks.com/matlabcentral/answers/93865-how-do-i-compute-the-r-square-statistic-for-robustfit-using-statistics-toolbox-7-0-r2008b
% that is, it's based on the sum of square of the regression. 
% 
% DA 2018/08/22

sse     = stats_rob.dfe * stats_rob.robust_s^2;
phat    = b_rob(1) + b_rob(2)*x;
ssr     = norm(phat-mean(phat))^2;
r2      = 1 - sse / (sse + ssr); 
return
end