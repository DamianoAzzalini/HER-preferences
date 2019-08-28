%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run_ttest_bayes
%%%
%%% This function runs the Bayes Factor test, by executing different steps:
%%% - compute the difference between data condition A and data condition B
%%% - run Bayes Factor computation (my_ttest_bayes)
%%% - get interpretation of the value of the Bayes Factor
%%%
%%% Inputs:
%%% - dataA, dataB: nx1, containing the mean data for each subject, with
%%% n=number of subjects, for condition A (dataA) and condition B (dataB).
%%% Experimental data does not need to be standardized because it will be
%%% automatically done in my_ttest_bayes
%%% - xref: value of the reference effect size (prior)
%%%
%%% Works with Matlab2012 (not 2009, 2010, 2011).
%%%
%%% Mariana Babo-Rebelo, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function [bf_log10, bf, res_Bayes] = run_ttest_bayes(dataA, dataB, xref)

xdat = dataA - dataB;

bf_log10 = my_ttest_bayes(xdat, xref);
[res_Bayes, bf] = interpret_Bayes(bf_log10);


