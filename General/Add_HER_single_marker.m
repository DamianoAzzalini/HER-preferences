function newEvents = Add_HER_single_marker(cfg,Events,display)
%% WRITE HELP WITH INPUT/OUTPUTS, TEST AGAIN

% newEvents = Add_HER_single_marker(cfg,Events,display)
% Add_HER_single_marker select the cardiac event defined as the input
% marker that (1) falls into a given phase of the trial,
% defined by two markers (mrk_beg & mrk_end) and (2) that
% happens N seconds after the mrk_beg M seconds before mrk_end.
%
% INPUTS:
%       - cfg               = structure with the fields
%
%            - cfg.SamplingFreq     = sampling frequency of the data.
%
%            - cfg.cardiac_marker = string. It
%                       indicates the name of cardiac marker on which the
%                       user will base the HER computations.
%
%            - cfg.mrk_beg     = string. It is the name of the marker that
%                       represents the beginning of the segment you want to
%                       compute the HERs for.

%           - cfg.mrk_end     = string. It is the name of the marker that
%                       represents the end of the segment you want to
%                       compute the HERs for.
%
%            - cfg.post_mrk_beg  = scalar (in seconds). It is the latency after
%                       cfg.mrk_beg for which the cardiac event is
%                       considered to be good candidate.
%
%           - cfg.pre_mrk_end  = scalar (in seconds). It is the latency to
%                       subtract from cfg.mrk_end before which the cardiac event
%                       is considered as good candidate.
% 
%           - cfg.MinIntTR     = scalar (in seconds). It is the minimal
%                                time that between the current T-peak and the 
%                                succesive R-peak so that the current T-peak is 
%                                consider valid to create the epoch. 
%                                
%           - cfg.output_mrk_name    = the suffix that will be added to the
%                       first letter of 'cfg.cardiac_marker' to create the
%                       new marker.
%   - Events            = Events structure with the experimental markers
%   - display           = True or false (logical)
%
% DA 2017/05/12
% DA 2017/06/10: added more input in the cfg structure for marker names,
%                sampling frequency. The name of the function is now
%                Add_HER_RandT_markers.
% DA 2017/06/19: If user is selecting either 'ITI' or 'ITI_diode' as
%                cfg.mrk_end the algorithm is automatically removing the
%                first occurence of it and throws a warning message.
% DA 2017/09/08: Corrected bug for conversion from seconds to samples of the 
%                MinIntTR. 
% DA 2017/09/11: Added warning message for exclusion of T-peaks that are
%                closer than cfg.MInIntTR (minimal interval T-R peaks).
%                Added txt feedback on how many T-peaks have been removed
%                because too close to following R-peak. 
% DA 2017/09/27: Output marker name is the one provided in cfg.output_mrk_name

%% GET PARAMETERS
% GET R marker & T marker names
input_mrk_name   = cfg.cardiac_marker;
% The beginning of the timewindow that is valid to select candidates
post_mrk_beg     = cfg.post_mrk_beg*cfg.SamplingFreq;
% The end of the timewindow that is valid to select candidates
pre_mrk_end      = cfg.pre_mrk_end*cfg.SamplingFreq;
% The minimum interval between T and following R to consider the T a
% candidate for HER
if strcmp(input_mrk_name,'T_sample') || strcmp(input_mrk_name,'T_sample_corrected'); 
    if ~isfield(cfg,'MinIntTR')
        error('You have not provided cfg.MinIntTR')
    end
    MinIntTR         = cfg.MinIntTR*cfg.SamplingFreq;
    warning('You''re excluding all %s that are < of %1.2f ms from next R-peak',input_mrk_name,MinIntTR); 
end
% Markers defining beginning and end of the segment you want to consider
S_mrk       = cfg.mrk_beg;
E_mrk       = cfg.mrk_end;

% Name of the new marker
new_event_name = cfg.output_mrk_name;

%% SELECT THE CANDIDATE R AND T FOR ANALYSES

% Retrieve samples defining start and end of segment you are considering
S_samples   = Get_samples(Events,S_mrk);
E_samples   = Get_samples(Events,E_mrk);

% If the end event is ITI, warn the user, but remove the first occurence
% since it's coming before the first WARNING
if (strcmp(E_mrk,'ITI') || strcmp(E_mrk,'ITI_diode')) && E_samples(1)<S_samples(1)
    warning('\n You''re using %s marker. I am removing the first occurence of it \n',E_mrk);
    E_samples(1) = [];
end

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

% Get the samples of the input cardiac event
cardiac_samples = Get_samples(Events,input_mrk_name);

% Determine the timewindow you should consider before the cardiac event
cardiac_tw_before = cardiac_samples-post_mrk_beg;
if any(cardiac_tw_before<=0)
    warning('Subtracting %1.2f seconds to %s cardiac event yields to negative samples',...
        cfg.post_mrk_beg,mat2str(find(cardiac_tw_before<=0)));
    warning('Setting the values for %s cardiac event equal to 1st sample', mat2str(find(cardiac_tw_before<0)));
    cardiac_tw_before(cardiac_tw_before<=0) = 1;
end
% Add PostT_tw ms to determine the timewindow to consider after T peak
cardiac_tw_after  = cardiac_samples+pre_mrk_end;
if any(cardiac_tw_after>Get_samples(Events,'lastsample'))
    warning('Adding %1.2f seconds to %s cardiac event yields to samples beyond the last one',...
        cfg.pre_mrk_end,mat2str(find(cardiac_tw_after>Get_samples(Events,'lastsample'))));
    warning('Setting the values for %s cardiac event equal to last sample', mat2str(find(cardiac_tw_after>Get_samples(Events,'lastsample'))));
    cardiac_tw_after(cardiac_tw_after>Get_samples(Events,'lastsample')) = Get_samples(Events,'lastsample');
end

% Select those who are falling in the period of interest
cardiac_event_in_segment = zeros(length(cardiac_tw_before),1);
for iB = 1:length(cardiac_tw_before)
    if all(segment_msk(cardiac_tw_before(iB):cardiac_tw_after(iB)))
        cardiac_event_in_segment(iB)     = 1;
    end
end
cardiac_event_in_segment = logical(cardiac_event_in_segment);

% If T-peak are used to compute HER, check that each T is at least beyond
% MinIntTR from the following R peak
if strcmp(input_mrk_name,'T_sample') || strcmp(input_mrk_name,'T_sample_corrected') 
    R_samples   = Get_samples(Events,'R_sample_corrected');
    if length(R_samples)~=length(cardiac_samples)
        error('R and T peaks differ in number')
    end
    R_candidates     = R_samples(find(cardiac_event_in_segment)+1); % +1 since its the index referring to the R after current T
    T_candidates     = cardiac_samples(cardiac_event_in_segment);
    LessThanCritic   = (R_candidates-T_candidates)<=MinIntTR;
    idx_in_segment   = find(cardiac_event_in_segment); 
    T_events2include = cardiac_event_in_segment;
    T_events2include(idx_in_segment(LessThanCritic==1)) = 0;
    T_events2include = logical(T_events2include); 
    candidate_events = cardiac_samples(T_events2include);
    fprintf('\n %d candidate T-peak(s) has/have been removed because T-R interval < %1.2f ms \n\n',sum(LessThanCritic),MinIntTR); 
    
% If you use R peaks all R falling within the period of interest are
% included 
else
    candidate_events = cardiac_samples(cardiac_event_in_segment);
end

%% PLOT IF REQUESTED (default)
if display ==true
    figure;
    h1 = plot(segment_msk./4,'b'); hold on
    % The good cardiac evets candidated for HER analysis
    h2 = plot(candidate_events,.10*ones(1,sum(cardiac_event_in_segment)),'b*'); hold on;
    % Plot all possible cardiac events (for comparison)
    h3 = plot(cardiac_samples,.07*ones(1,length(cardiac_samples)),'gd'); hold on;
    % Legend
    set(gca,'YLim',[0 max(segment_msk./4)+0.05]);
    legend([h2 h3], {'Candidate cardiac event','all cardiac event'});
end
%% CREATE OUTPUT WITH NEW NAMES

% Create structure to add events
events2add = struct();

% The candidate event's samples
for i = 1:length(candidate_events)
    events2add(i).(new_event_name) = candidate_events(i);
end

[newEvents] = add_Events(Events,events2add,0,0);

end