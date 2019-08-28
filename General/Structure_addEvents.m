function Struct_Events = Structure_addEvents(samples_mrks,marker_name)

% Structure_addEvents creates a 1xlength(sample_mrks) structure with one
% field name 'marker_name'. This function produces the right structure to
% pass on as input to add_Events function 
% 
% INPUT:    - samples_mrks = Nx1 vector of samples 
%           - marker_name  = string, the name to assign to the fields of
%                            Struct_Events
% DA 2017/06/06

% Create an empty structure 
Struct_Events = struct([]); 
% Check if inputs are correct 
if size(samples_mrks,2) > 1 
    error('\n You should provide a Nx1 vector'); 
end
if ~isa(marker_name,'char')
    error('Second input has to be a string')
end
% Check whether there are events that happen before the first sample. In
% this case set those values to 1 (first sample)
if any(samples_mrks<1)
   warning('There are events that happen before the 1st sample. Setting those values to ones'); 
   samples_mrks(samples_mrks<1) = 1;
end

% For each entry of sample_mrks create a field with the name marker_name
    for iE = 1:length(samples_mrks)
        Struct_Events = setfield(Struct_Events,{iE},marker_name,samples_mrks(iE)); 
    end
    
end