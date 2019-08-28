%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% interpret_Bayes
%%%
%%% This function gives the interpretation of a Bayes Factor, in terms of
%%% how much it supports H1 against H0.
%%% The classification applied here corresponds to the one developped by
%%% Kass & Raftery, Journal of the American Statistical Association, 1995.
%%%
%%% Caution:
%%% The interpretation of the Bayes Factor depends on what is considered as
%%% H0 and what is considered as H1. In the current implementation of the
%%% Bayes Factor computation (in log10), a BF<0 shows evidence in favor of
%%% H1 (there is a true effect between conditions), and BF>0 shows evidence
%%% in favor of H0 (the null hypothesis is true). 
%%%
%%% Input:
%%% - bf_log10: Bayes Factor value in log10
%%%
%%% Output:
%%% - res_Bayes: the result of the Bayes Factor test, i.e. what theory does
%%% our data support and how strongly
%%% - bf: Bayes Factor (not in log10)
%%%
%%% Mariana Babo-Rebelo, 2016
%%% 16/01/2019 DA: Correct line 32 that previously used the absolute value
%%%                of log(BF) to compute BF. Now there is no absolute value 
%%%                anymore and the BF returned by the function should be correct. 
%%% 17/01/2019 DA: changed line 55: now bf_log10 > 0 supports H1, that
%%%                is the hypothesis that there is a true difference between conditions. 
%%%                H0 = no difference between conditions. 
%%%                Added line 38
%%%                Added line 61
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [res_Bayes, bf] = interpret_Bayes(bf_log10)

fprintf('\n --------------------------- \n Interpretation key (DA): \n H0 = no difference between conditions;  H1 = true effect \n ---------------------------\n\n'); 

abs_bf_log10 = abs(bf_log10);
bf           = 10^(bf_log10);  % This is where the error was (Mariana figured it out the 9th January 2019)

if abs_bf_log10 < 0.5
    res_Bayes = 'Anecdotal evidence for ';
elseif abs_bf_log10 >= 0.5 && abs_bf_log10 < 1
    res_Bayes = 'Substantial evidence for ';
elseif abs_bf_log10 >= 1 && abs_bf_log10 < 2
    res_Bayes = 'Strong evidence for ';
elseif abs_bf_log10 >= 2
    res_Bayes = 'Decisive evidence for ';
else
    error('Something wrong with Bayes Factor computation');
end

if bf_log10 > 0
    res_Bayes = [res_Bayes 'H1'];
else
    res_Bayes = [res_Bayes 'H0'];
end

fprintf('\n BF-log10 = %1.4f',bf_log10);  % Added to have Valentin's result as well. 

end