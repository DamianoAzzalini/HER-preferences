function [unique_values,occurences] = count_occurences(X,values2find)

switch nargin
    case 1 
        unique_values = unique(X); 
        l = length(unique_values); 
        occurences = NaN(l,1); 
        
        for iO = 1:l 
            occurences(iO) = sum(X==unique_values(iO));
        end
        
    case 2
        unique_values = values2find; 
        l = length(unique_values); 
        occurences = NaN(l,1); 
        
        for iO = 1:l
            occurences(iO) = sum(X==unique_values(iO)); 
        end
end

end