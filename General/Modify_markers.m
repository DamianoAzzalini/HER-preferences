function newEvents  = Modify_markers(Events,marker2modify,time,name_new_marker)

% This function allows you to create new markers, simply
% adding/subtracting some time (expressed in samples) to/from the existing
% ones. It has been created to adjust the visual triggers to the actual
% presentation on the screen (photodiode delay), filtering issue with the
% cardiac signal (filters on BIOPAC) and RT correctin due to SafeWaitSecs 
% from WaitForLumina function (Laurent's). 
% 
% INPUTS:   - Events            = structure containing the experiment's markers
%           - marker2modify     = string. It is the name of the marker to
%                                 modify. 
%           - time              = scalar in samples (verify that the sampling 
%                                 frequency has not been modified from the original 
%                                 acquisition/marker definition). It is the
%                                 amount of time by which the marker will be shifted 
%           - name_new_marker   = string, it is the name to assigned to the newly created 
%                                 marker. 
% 
% OUTPUT:   - NewEvents         = structure similar to input Events structure but with the 
%                                 markers 'name_new_marker' appended to it.
% 
% DEPENDENCIES:                 
%                               - Get_samples.m
%                               - Structure_addEvents.m
%                               - add_Events.m
% 
% DA 2017/06/06

% Verify that the marker to modify is present in the structure
if ~any(strcmp(unique({Events.type}),marker2modify))
    error(' The marker %s to modify does not exist',marker2modify); 
end
% Extract the samples for input marker
old_mrk_samples     = Get_samples(Events,marker2modify)';

% Verify that there are samples for the marker the user want to change
if isempty(old_mrk_samples)
   error(' There are NO SAMPLES for the marker %s',marker2modify); 
end

% Create structure to pass on to add_Events
corrected_event     = Structure_addEvents((old_mrk_samples+time),name_new_marker);

% Add new marker with the samples in the newEvents structure
newEvents           = add_Events(Events,corrected_event,0,0);

% Check that the modification of the older markers has been succesuful 
if any(((Get_samples(newEvents,name_new_marker))' - (Get_samples(newEvents,marker2modify))') ~= time)
    error('The modification of %s into %s does not correspond to %d samples in all the instances',marker2modify,name_new_marker,time);
end

end