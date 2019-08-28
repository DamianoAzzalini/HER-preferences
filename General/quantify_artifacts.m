function [NrejectedTrials,TrialRejected] = quantify_artifacts(Mask)
% [NrejectedTrials,TrialRejected] = quantify_artifacts(Mask)
% 
% This function quantifies trial rejection. 
% It returns the number of trials rejected because they contain an artifact
% and they corresponsing percentage with respect to the total number of
% trial. 
% INPUT:        - Continuous mask with artifacts, blinks, trials and
%                 saccades information.
% 
% OUTPUT:       - NrejectedTrials:  how many trials contain artifacts (scalar)
%               - TrialRejected:    the trials which contain artifacts (Nx1 vector)
% 

% DA 2017/04/14
% DA 2017/04/20: TrialRejected vector is now a Nx1 array
% DA 2017/05/02: Spelling of continuous have been changed according to
%                Create_mask_prefer's one. 

% Extract all timepoints marked as bad (1 in BadContinuous) & that have a value different from 0
% (in TrialContinuous). 
% Which trials are those? These are the rejected ones
TrialRejected = unique(Mask.TrialContinuous(Mask.BadContinuous==1&Mask.TrialContinuous~=0))'; 

% How many trials have been rejected
NrejectedTrials = length(TrialRejected);

return
end