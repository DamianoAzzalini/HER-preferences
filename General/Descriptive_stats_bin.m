function [Mean,SEM] = Descriptive_stats_bin(data,bin_vector)

% The function computes the mean and the SEM for each bin value 
% in a the input 1-dimensional vector of data. 
% Mean and SEM are organized organized in ascending order (1st value
% is smaller than 2nd and so on). 
% INPUT:            - data:         1-dimensional vector
%                   - bin_vector:   1-dimensional vector of the same length
%                                   as data. 
% DA 2017/06/06

% Check that the behavioral_measure and the bin_vector have the same sime
if size(data)~=size(bin_vector)
    error('The 2 input vectors have different sizes'); 
end

% Unique values in bin_vector
UniBin = unique(bin_vector); 

% Initialize variables
Mean = NaN(length(UniBin),1); 
SEM  = NaN(length(UniBin),1); 

% Loo through the number of bins
for ii = 1:length(UniBin)
    % Compute mean for the current bin 
    Mean(ii) = mean(data(bin_vector==UniBin(ii))); 
    % SEM across trials for the current bin
    SEM(ii)  = std(data(bin_vector==UniBin(ii)))/sqrt(length(data(bin_vector==UniBin(ii))));
end

end