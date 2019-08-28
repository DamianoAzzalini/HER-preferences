function SaccadeContinuous = Saccades_Continuous_vector(Events,data_length)
% 
% SaccadeContinuos = Saccades_continuos_vector(Events,data_length)
% 
% This function creates a continuos vector (of the same length as data_length)
% that has 0s in all the samples in which no saccades or saccades below
% 1 degree occur, 1s for samples in which saccades between 1 and 2 degree
% occur, 2s, 3s, 4s and 5s following the same logic. 
% INPUT: 
%   - Events:       Structure obtained converting mrk files into mat
%   - data_length:  1x2 vector indicating the time dimension of the
%                   continuos data: [1 end_sample]
% 
% DA 2017/03/03 

% Initialize continuos vector of the same length of the continuos data 
SaccadeContinuous = zeros(data_length);

% Check whether the eye tracked was left or right
mrks = unique({Events.type});
left = sum(strcmp(mrks,'EL_SBLINK_L'));
right = sum(strcmp(mrks,'EL_SBLINK_R'));
if left == 1 && right == 0
    tracked_eye = 'L';
elseif right == 1 && left == 0
    tracked_eye = 'R';
else
    error('It''s not possible to determine which eye was tracked')
end

% loop through all possible degrees of saccade (we are not considering degree = 0)
for sDegree = 0:5 
    % Saccade name for current degree 
    SaccNameStart     = ['EL_SSACC_' tracked_eye '_' num2str(sDegree)]; 
    SaccNameEnd       = ['EL_ESACC_' tracked_eye '_' num2str(sDegree)]; 
    SaccPresent  = sum(strcmp(mrks,SaccNameStart));
    % If the current saccade is present 
    if SaccPresent == 1
       SaccStart = sort(Get_samples(Events,SaccNameStart)); 
       SaccEnd   = sort(Get_samples(Events,SaccNameEnd)); 
       % Control that everything is in right time order
       ctrl_order_samples(SaccStart,SaccEnd) ;
       % For each segment put the degree of the saccade in the continuos
       % vector
        for iSacc = 1:length(SaccStart)
            SaccadeContinuous(SaccStart(iSacc):SaccEnd(iSacc)) = sDegree+1;
        end
    end
end


end