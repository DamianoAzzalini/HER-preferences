function newEvents = Add_HER_RandT_markers(cfg,Events,display)

% newEvents = Add_HER_RandT_markers(cfg,Events,display)
% Add_HER_RandT_markers select the pairs of R-T peaks, (1) which fall into a given
% phase of the trial, defined by two markers (mrk_beg & mrk_end) and (2) in which
% the R-peak happens N seconds after the mrk_beg and whose T-peak happens M
% seconds before mrk_end. 
% 
% INPUTS: 
%       - cfg               = structure with the fields
% 
%            - cfg.SamplingFreq     = sampling frequency of the data. 
%
%            - cfg.R_cardiac_marker = string. It
%                       indicates the name of the R-peak cardiac marker. 
%
%            - cfg.T_cardiac_marker = string. It
%                       indicates the name of the T-peak cardiac marker.
% 
%            - cfg.mrk_beg     = string. It is the name of the marker that
%                       represents the beginning of the segment you want to
%                       compute the HERs for. 
%
%            - cfg.mrk_end     = string. It is the name of the marker that
%                       represents the end of the segment you want to 
%                       compute the HERs for. 
% 
%            - cfg.post_mrk_beg  = scalar (in seconds). It is the latency after  
%                       cfg.mrk_beg for which R- is
%                       considered to be candidates. 
% 
%           - cfg.pre_mrk_end  = scalar (in seconds). It is the latency to 
%                       subtract from cfg.mrk_end for which T-peak 
%                       is considered as valid. 
%   
%           - cfg.output_mrk_name    = the suffix that will be added to 'R'
%                       and 'T' to create the new candidate
%                       R and T peaks for HER computations;
%   - Events            = Events structure with the experimental markers
%   - display           = True or false (logical)
% 
% DA 2017/05/12
% DA 2017/06/10: added more input in the cfg structure for marker names,
%                sampling frequency. The name of the function is now 
%                Add_HER_RandT_markers. 
%% GET PARAMETERS
% GET R marker & T marker names
R_mrk_name = cfg.R_cardiac_marker;
T_mrk_name = cfg.T_cardiac_marker;
% Time window before R to consider the pair of peaks as valid
post_mrk_beg     = cfg.post_mrk_beg*cfg.SamplingFreq;
% Time window After T to consider the pair of peaks as valid
pre_mrk_end    = cfg.pre_mrk_end*cfg.SamplingFreq;

% Markers defining beginning and end of the segment you want to consider
S_mrk       = cfg.mrk_beg;
E_mrk       = cfg.mrk_end;

% Name of the new marker
new_event_name = cfg.output_mrk_name;

fieldNameR = ['R_',new_event_name];
fieldNameT = ['T_',new_event_name];

%% SELECT THE CANDIDATE R AND T FOR ANALYSES

% Retrieve samples defining start and end of segment you are considering
S_samples   = Get_samples(Events,S_mrk);
E_samples   = Get_samples(Events,E_mrk);
% Check that the limits of the segments have the same number of occurence
% and that are ordered
if length(S_samples)~=length(E_samples)
    error('The markers defining the segment of interest have different length');
end
if any(S_samples>=E_samples)
    error(['The marker delimiting the segment of interest are not in the right order.'...
        ' Make sure the marker defining the beginning comes first than the marker delimiting the end']);
end
% create continuos mask for this segment
segment_msk = zeros(1,Get_samples(Events,'lastsample'));
for ii = 1:length(S_samples)
    segment_msk(S_samples(ii):E_samples(ii))= 1;
end

% Get all the Rs and Ts
R_samples = Get_samples(Events,R_mrk_name);
T_samples = Get_samples(Events,T_mrk_name);

% Throw an error if R and T have different length
if length(R_samples)~=length(T_samples)
    error('R and T peaks differ in number')
end

% Subtract N ms to determine the timewindow you should consider before the
% R peak
R_tw_before = R_samples-post_mrk_beg;
R_tw_before(R_tw_before<0) = 1;
% Add pre_mrk_end ms to determine the timewindow to consider after T peak
T_tw_after  = T_samples+pre_mrk_end;
T_tw_after(T_tw_after>Get_samples(Events,'lastsample')) = Get_samples(Events,'lastsample');

% Select those who are falling in the period of interest
PairBeats_in_Segment = zeros(length(R_tw_before),1);
for iB = 1:length(R_tw_before)
    if all(segment_msk(R_tw_before(iB):T_tw_after(iB)))
        PairBeats_in_Segment(iB)     = 1;
    end
end
PairBeats_in_Segment = logical(PairBeats_in_Segment);
candidate_R = R_samples(PairBeats_in_Segment);
candidate_T = T_samples(PairBeats_in_Segment);

%% PLOT IF REQUESTED (default)
if display ==true
    figure;
    plot(segment_msk./4,'b'); hold on
    % The good candidates for HER analysis
    plot(candidate_R,.10*ones(1,sum(PairBeats_in_Segment)),'rd'); hold on;
    plot(candidate_T,.09*ones(1,sum(PairBeats_in_Segment)),'b*');
    % Plot all the R and T peaks (for comparison)
    plot(R_samples,.07*ones(1,length(R_samples)),'gd'); hold on;
    plot(T_samples,.06*ones(1,length(T_samples)),'g*');
    legend({'Trial segment','Candidate R','Candidate T','R sample','T sample'});
end
%% CREATE OUTPUT WITH NEW NAMES

% Create structure to add events
events2add = struct();

% The candidate samples for R
for i = 1:length(candidate_R)
    events2add(i).(fieldNameR) = candidate_R(i);
end
% The candidate samples for T
for i = 1:length(candidate_T)
    events2add(i).(fieldNameT) = candidate_T(i);
end

[newEvents] = add_Events(Events,events2add,0,0);

end