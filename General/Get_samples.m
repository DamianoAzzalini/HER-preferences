%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Get_samples
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [mrk_samples] = Get_samples(Events, mrk_name)

mrk_ind = find(strcmp(mrk_name, {Events.type}));

mrk_samples = sort([Events(mrk_ind).sample]);

% if isempty(mrk_samples)
%     warning(['No markers "' mrk_name '" found.']);
% end

end











