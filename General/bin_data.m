function [binned_data, old_data, Bin_stats] = bin_data(data,Nbins)

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


% count occurences for each value in data vector
[Unival,NOccurence] = count_occurences(data); 
% each value corresponds to % of the data 
DataPercent = NOccurence./length(data); 
% get how much each bin should contain 
BinPercent = 1/Nbins; 

% grouped original bins so that they are the closest to optimal solution 
StartBin = 1; 
EndBin = 1; 

for iBin = 1:Nbins
    almost_opt = 0; 
    while almost_opt == 0
        % For latest bin, all the data from previous one until the end
        if iBin == Nbins 
           currBinning = sum(DataPercent(StartBin:end)); 
           almost_opt = 1; 
        else
            % start from bin one
           currBinning = sum(DataPercent(StartBin:EndBin)); 
            % check whether adding one makes the bin closer to the optimal
            % percentage
            nextBinning = sum(DataPercent(StartBin:EndBin+1)); 
            % if it's better to add one, do it 
            if currBinning < BinPercent && abs(currBinning-BinPercent) > abs(nextBinning-BinPercent)
                EndBin = EndBin+1; 
                % else it's the best solution    
            else
                almost_opt = 1; 
            end
        end
    end
    
    % Indeces where the bin starts
    Bin_idx(iBin,1) = StartBin; 
    % Percentage of trials corresponding to the current bin 
    Bin_perc(iBin,1) = currBinning; 
    % StartBin for next iteration == EndBin of previous + 1
    StartBin = EndBin+1; 
    % EndBin == StartBin 
    EndBin = StartBin;       
end

% re-assign deltaQ values according to quantiles 
binned_data = NaN(length(data),1); 
Ntrials_bin = NaN(length(Bin_idx),1);
for iQ = 1:length(Bin_idx)
    % if it's the first bin, all values smaller than first split_point
    if iQ == length(Bin_idx)
        idx_currData = data>=Unival(Bin_idx(iQ)); 
        binned_data(idx_currData) = iQ; 
    % all other bins, larger or equal than current split_point but smaller
    % than the following one
    else 
        idx_currData = data<Unival(Bin_idx(iQ+1))&data>=Unival(Bin_idx(iQ)); 
        binned_data(idx_currData) = iQ; 
    end
    
    % Number of trials in the current bin
    Ntrials_bin(iQ) = sum(idx_currData); 
    % clear indeces 
    idx_currData = []; 
end
% The edge values for each bin
Bin_edges = Unival(Bin_idx); 
% old Deltas use for the binning
old_data = data; 

% Return a structure with the statistics for the bins 
Bin_stats.Ntrials_bin = Ntrials_bin; 
Bin_stats.Bin_perc    = Bin_perc; 
Bin_stats.Bin_edges   = Bin_edges; 

end 