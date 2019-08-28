function [binned_data,old_data,binstat] = bin_2side_zero(data,BinsPerSide)
% This function creates the same number of bins (BinsPerSide) for
% positive and negative values. This ensures that positive and negative values are
% not put into the same bin. 
%
% Dependency: bin_data.m 
% 
% NOTE: 
% This specific binning solution is used to fit the psychometric function
% depending on HER amplitude. 
%
% DA 2017/12/14

pos_data = data(data>0);
[Pos_bins,~,stat_pos] = bin_data(pos_data,BinsPerSide); 
neg_data = data(data<0);
[Neg_bins,~,stat_neg] = bin_data(neg_data,BinsPerSide); 

% CREATE OUTPUT 
binned_data = NaN(size(data)); 
binned_data(data>0) = Pos_bins; 
binned_data(data<0) = Neg_bins-(BinsPerSide+1);

% OLD DATA 
old_data = data; 

% BIN STATS
[~,binstat.Ntrials_bin] = count_occurences(binned_data); 
binstat.Bin_perc    = binstat.Ntrials_bin./length(data); 
binstat.Bin_edges   = [stat_pos.Bin_edges; stat_neg.Bin_edges]; 

end