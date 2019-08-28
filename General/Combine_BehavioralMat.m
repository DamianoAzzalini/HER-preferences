function res = Combine_BehavioralMat(stim_matrix,response_matrix)

% res = Combine_BehavioralMat(stim_matrix,response_matrix)
%
% The function combines the stimulation matrix from the design with the
% matrix containing the responses given by the subject. 
% INPUT: 
%    - stim_matrix:     structure containing all the information about the 
%                       stimulation
%    - response_matrix: structure containing all the subject's responses and 
%                       timings of the run. 
% OUTPUT:
%    - res:             The same as the stimulation matrix with the responses,
%                       performances, RTs and pre-computed correct
%                       responses added. 
%                       
% DA 2017/04/17

res             = stim_matrix; 
res.Resp        = response_matrix.resp; 
res.RT          = response_matrix.RT; 
res.Perf        = response_matrix.perf; 
res.CorrectResp = response_matrix.Correct; 

end