function status = ctrl_order_samples(begin_samples,end_samples)

% This function controls that begin_samples and end_samples are arranged in
% the right order (from the smallest to the largest) and that the
% begin_samples occur before (in time, i.e. smaller samples) the
% corresponding end_samples. 
% If there is an inconsistency, the funciton throws an error. 
% 
% INPUT: 
%   - begin_samples: 1xN vector of samples indicating the begin of a
%                    segment
%   - end_samples:   1xN vector of samples indicating the end of a segment
% 
% DA 2017/03/03

% Are begin and end samples sorted in the right time 
BsgmntSort = diff(begin_samples); 
EsgmntSort = diff(end_samples); 
if any(BsgmntSort<=0) 
    error('Begin samples are not sorted in time'); 
elseif any(EsgmntSort<=0)
   error('End samples are not sorted in time'); 
end

% Are all begin samples preceding the end samples in time? 
BeginEndElapse = end_samples-begin_samples; 
if any(BeginEndElapse<0) 
   error('There are some segments in which the start of the trial is later than the end')
end 

status = 1; 

end