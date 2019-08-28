function Events = remove_markers(Events,mrk_name)

% Events = remove_markers(Events,mrk_name)
%
% This function removes the markers specified as the second input from the
% Events structure
%
% DA 2017/11/22


% Initial size of Events structure 
Beg_size            = size(Events,2); 
% Get indeces of the markers you want to remove 
mrk2remove          = find(strcmp(mrk_name, {Events.type}));
% Remove in all fields those indeces 
Events(mrk2remove)  = []; 
% Check that you are removing the right number 
if (Beg_size-size(Events,2)) ~= length(mrk2remove)
    error(' Events to remove are incorrect') ;
elseif any(strcmp(unique({Events.type}),mrk_name))
    error(' Not all events were correctly removed. Manual check required'); 
end

end