function [NewEvents] = remove_field(NewEvents,fieldstring)

Newfieldname = fieldnames(NewEvents);
for i=1:size(Newfieldname,1) 
    if ~isempty(strfind(Newfieldname{i},fieldstring))
        NewEvents = rmfield(NewEvents,Newfieldname{i});
    end
end

        