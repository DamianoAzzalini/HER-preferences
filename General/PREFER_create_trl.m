function trl = PREFER_create_trl(cfg)
% trl = PREFER_create_trl(cfg)
%
% The function creates the trl matrix necessary to epoch the data with
% the native FieldTrip ft_definetrial. 
% INPUTS:   cfg.trialdef.fsample        = scalar: sampling frequency in Hz
%           cfg.trialdef.Events_struct  = Events structure. The one created
%                                         from the dataHandler markers
%           cfg.trialdef.eventtype      = string contained in the Events
%                                         structure to retrieve the event
%                                         corresponding the time0 of the
%                                         epoched data
%            cfg.trialdef.prestim       = scalar or Nx1 vector of scalars
%                                         indicating
%                                         the pre-stimulus interval to include 
%                                         in the epochs. IT HAS TO BE IN SECONDS
%            cfg.trialdef.poststim       = scalar or Nx1 vector of scalars
%                                         (to create variable trial's
%                                         lengths) indicating
%                                         the post-stimulus interval to include 
%                                         in the epochs. IT HAS TO BE IN SECONDS

% DA 2017/05/26 (modified and commented)

% Retrieve the events of interest from the Events structure
if strcmp(cfg.trialdef.eventtype,'RESP_corrected_12ms')
    fprintf('\n Segmenting data using %s. \n Including NO_RESP triggers (if present) \n',cfg.trialdef.eventtype);
    % If trials are epoched around the responses, include NO_resp as
    % trigger
    Resp    = Get_samples(cfg.trialdef.Events_struct,'RESP_corrected_12ms')'; % retrieve and correct for delay
    No_Resp = Get_samples(cfg.trialdef.Events_struct,'NO_RESP')';
    if ~isempty(No_Resp)
        events_of_interest   = sort([Resp; No_Resp]);
    else 
        events_of_interest   = Resp; 
    end
elseif strncmpi(cfg.trialdef.eventtype,'RESP',4) && ~strcmp(cfg.trialdef.eventtype,'RESP_corrected_12ms')
    error(' Epoching around RESP is only coded for RESP_corrected_12ms. ')
else
    events_of_interest = Get_samples(cfg.trialdef.Events_struct,cfg.trialdef.eventtype)';
end
% control that events are ordered in time 
if any(diff(events_of_interest)<0)
    error('Samples are not ordered in time')
end 
% determine the number of samples before and after the trigger
pretrig  = round(cfg.trialdef.prestim  * cfg.trialdef.fsample);
posttrig =  round(cfg.trialdef.poststim * cfg.trialdef.fsample);

% Determine the actual samples pre & post stim
prestim_samples =  events_of_interest - pretrig; 
poststim_samples = events_of_interest + posttrig; 

% return the epoching definition into trl matrix 
trl = [prestim_samples poststim_samples (prestim_samples-events_of_interest)]; 

return

end