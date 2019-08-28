function [Mask] = Create_mask_prefer(event,keep,plot_figure)


% Create a mask to help in selecting the good marker
% Input
%     event           struct in fieldtrip format containing all behavioral events
%     keep            struct containing all the infos for the ICA
%     plot_figure     0 or 1
% Output
%     Mask            struct containing vectors of 1 and 0, one per marker (begin, end, blink, saccade-coded in amplitude)
%
% DA 2017/06/27: Beginning and End of the trial are now determined by
%                WARNING_diode and ITI_diode, i.e. the corrected markers for presentation
%                delay (line 69-70). 

data_length = [1 event(find(strcmp({event.type},'lastsample'),1)).sample];

%% Vector continuous bad segments
BadContinuous = zeros(data_length);
BadS_sample = sort(Get_samples(event,'BAD_Begin'));
BadE_sample = sort(Get_samples(event,'BAD_End'));

% Check that the dimensions of the bad segments fit
if length(BadS_sample)~=length(BadE_sample)
    error('Start and End samples of Bad segments have different length')
end
% Controls that everything is in right time order
ctrl_order_samples(BadS_sample,BadE_sample); 

% For each segment put 1s wherever there is a bad segment
for iBad = 1:length(BadS_sample)
    BadContinuous(BadS_sample(iBad):BadE_sample(iBad)) = 1;
end

%% Vector continuous eyeblinks

% Check whether the eye tracked was left or right
mrks = unique({event.type});
left = sum(strcmp(mrks,'EL_SBLINK_L'));
right = sum(strcmp(mrks,'EL_SBLINK_R'));
if left == 1 && right == 0
    tracked_eye = 'L';
elseif right == 1 && left == 0
    tracked_eye = 'R';
else
    error('It''s not possible to determine which eye was tracked')
end

% Vector continuous eyeblinks
BlinkContinuous = zeros(data_length);
BlinkS_sample = sort(Get_samples(event,['EL_SBLINK_' tracked_eye]));
BlinkE_sample = sort(Get_samples(event,['EL_EBLINK_' tracked_eye]));

% Controls that everything is in right time order
ctrl_order_samples(BlinkS_sample,BlinkE_sample); 

% For each segment put 1s wherever there is blink
for iBad = 1:length(BlinkS_sample)
    BlinkContinuous(BlinkS_sample(iBad):BlinkE_sample(iBad)) = 1;
end

%% Continuous vector containing saccades

SaccadeContinuous = Saccades_Continuous_vector(event,data_length);

%% Continuous vector of Trial Number (from warning to ITI)

TrialContinuous = zeros(data_length);
Warning_sample = sort(Get_samples(event,'WARNING_diode')); 
ITI_sample     = sort(Get_samples(event,'ITI_diode'));

% remove first ITI, since it's not between trials 
if ITI_sample(1) < Warning_sample(1)
   ITI_sample(1) = []; 
end
% Control that you have the same number for Warning & ITI 
if length(ITI_sample)~=length(Warning_sample) 
       error('Warnings and ITI numbers mismatch')
end

% Controls that everything is in right time order
ctrl_order_samples(Warning_sample,ITI_sample); 

% Loop through the Warning and ITI, for all the samples
% contained between them belong write the number of trial 
for iT = 1:length(Warning_sample)
    TrialContinuous(Warning_sample(iT):ITI_sample(iT)) = iT; 
end

%% Create figure to check everything is in order 
if plot_figure == true

    figure; 
    % Number of trilas
    plot(TrialContinuous,'b:'); hold on; 
    % Bad segments (==1)
    plot(BadContinuous,'r'); 
    % Blinks
    plot(BlinkContinuous,'m'); 
    % Saccades (1 to >5 degrees);
    plot(SaccadeContinuous,'g')
    title('Mask on Continuous data'); 
    legend({'Trial #','Bad Segments','Blinks','Saccades'}); 
end

% Return the output 
Mask.TrialContinuous     = TrialContinuous; 
Mask.BadContinuous       = BadContinuous; 
Mask.BlinkContinuous     = BlinkContinuous; 
Mask.SaccadeContinuous   = SaccadeContinuous; 
