function [binned_data, old_data, Bin_stats] = bin_data_quantiles(data,Nbins)

% [binned_data, old_data, Bin_stats] = bin_data(data,Nbins)
% 
% The function bins the data in a roughly equally distributed manner
% INPUT: 
%       - data:     1xN vector to bin
%       - Nbins:    scalar, corresponding to the number of bins to create
%                   from data vector
% OUTPUTS: 
%       - binned_data:  1xN vecotr (same length as data). ith entry indicates 
%                       to which bin the ith vlaue in data belongs. 
%       - old_data:     input values of the data vector 
%       - Bin_stats:    structure with fields: 
%               - Ntrials_bin:  1xNbins vector. It contains the number of
%                               trials included in each bin. 
%               - Bin_perc:     1xNbins vector. Contains the percentage of data per
%                               each bin. (sum(Bin_perc)=1). 
%               - Bin_edges:    The value within each bin is bounded. 
%                               bin(i) = x>=Bin_edges(i) && x < Bin_edges(i+1) 
%               
% DA 2017/02/14
% DA 2017/04/13: Modified output. Bin_stats structure contains the
%                the number and the percentage of trials in each bin as
%                well as the bin edges.

% Compute the quantiles corresponding to Nbins-1
Bin_edges = quantile(data,Nbins-1); 
% re-assign deltaQ values according to quantiles 
binned_data = NaN(length(data),1); 
Ntrials_bin = NaN(Nbins,1);
for iQ = 1:Nbins
    % if it's the first bin, all values smaller than first split_point
    if iQ == Nbins
        idx_currData = data>=Bin_edges(end); 
        binned_data(idx_currData) = iQ; 
    % For the first bin take all values below the first quantile
    elseif iQ == 1
        idx_currData = data<Bin_edges(iQ);
        binned_data(idx_currData) = iQ;
    % all other bins, larger or equal than current split_point but smaller
    % than the following one
    else 
        idx_currData = data<Bin_edges(iQ)&data>=Bin_edges(iQ-1); 
        binned_data(idx_currData) = iQ; 
    end
    
    % Number of trials in the current bin
    Ntrials_bin(iQ) = sum(idx_currData); 
    % clear indeces 
    idx_currData = []; 
end
% old Deltas use for the binning
old_data = data; 

% Return a structure with the statistics for the bins 
Bin_stats.Ntrials_bin = Ntrials_bin; 
Bin_stats.Bin_perc    = Ntrials_bin./length(data); 
Bin_stats.Bin_edges   = Bin_edges; 

end 