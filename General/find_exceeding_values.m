function [id_above,id_below,val_above,val_below] = find_exceeding_values(data,std_value,feedback)

if ~isvector(data)
    error(' Data has to be a 1xN or Nx1 vector');
end

if nargin<3
    feedback = true;
end

if any(isnan(data))
    warning('\n Data contain NaNs. Excluding them from computation \n');
end

id_above = find(data>=(nanmean(data)+(std_value*nanstd(data))));
id_below = find(data<=(nanmean(data)-(std_value*nanstd(data))));

val_above = data(id_above);
val_below = data(id_below);

if feedback == true
    fprintf('\n Threshold value is set to %1.2f +- %1.2f (mean+-std). Limits = %s',nanmean(data),nanstd(data),...
        mat2str([nanmean(data)+(std_value*nanstd(data)) nanmean(data)-(std_value*nanstd(data))],4));
end

end