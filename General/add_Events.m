function [Events] = add_Events(Events,NewEvents,option,display)

% Update the events structure with new events. Value and duration are set
% empty and 0 by default.
% 
% Input:
%     Events      initial Events structure with field type, value, sample, duration, offset
%     NewEvents   structure containing the new Events to add
%     option      0: discard event if already exists, 
%                 2: append anyway
%     display     plot the data with the associated marker
% Outputs:
%     Events      updated structure with the same field as the initial structure

if nargin < 2
    error('Need new events to update initial Events')
elseif nargin < 1
    error('Need data to process')
end

Newfieldnames = fieldnames(NewEvents);
for nfield = 1:length(Newfieldnames)
    Double1 = find(strcmp({Events.type},Newfieldnames{nfield}));
    for nHB = 1:numel(NewEvents)
        Double2 = find([Events(Double1).sample] == getfield(NewEvents,{nHB},Newfieldnames{nfield}));
        if ~isempty(Double2) && option == 0
            disp('Event already exists')
        else
        ind = numel(Events)+1;
        Events(ind).type = Newfieldnames{nfield};
        Events(ind).value = [];
        Events(ind).sample = getfield(NewEvents,{nHB},Newfieldnames{nfield});
        Events(ind).duration = 0;
        Events(ind).offset = Events(ind).sample-1;
        end
    end
end

if display == 1
    cfg.dataset = filename;
    cfg.channel = channelname;
    data = ft_preprocessing(cfg);
    prompt = {'which channels?','which Markers?'};
    markname = inputdlg(prompt);

    indchannel = strcmp(data.hdr.label,markname{1});
    figure
    plot(data.trial{1}(indchannel,:));
    hold on
    indmark = strcmp({Events.type},markname{2});
    plot([Events(indmark).sample],data.trial{1}(indchannel,[Events(indmark).sample]),'go')
end