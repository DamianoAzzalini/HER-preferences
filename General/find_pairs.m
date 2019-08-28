function containing_trials = find_pairs(appended_data,movie_titles)
%
% containing_trials = find_pairs(appended_data,movie_titles)
% It return the number of trials containing the movie titles
% specified in movie_titles and prints on the screen
% the input titles as well as how many trials were found.
% INPUTS:
%   - appended_data: any structure of behavior containing 'SeenMovies' &
%                   'Pairs' fields.
%   - movie_titles:  1xN cell array containing either the exact movie titles to remove
%                    and/or the scalar indicating the index of the moive in the field
%                    SeenMovies of the input appended_data
% EXAMPLE CALL:
%   containing_trials = find_pairs(appended_data,{'Scream3','LesProfs'},49)
%
% DA 2017/04/19
% DA 2017/05/02: Adapted to output of Combine_BehavioralMat and tested
% DA 2017/06/06: Added the option of entering a scalar indicating the
%                number index of movie title in the field 'SeenMovies'. This is to circumvent
%                problems due to accents not encoded if the locale of the
%                system does not recognize french accents.

containing_trials = [];

for iM = 1:length(movie_titles)
    % If the input of the function is a string seach for the corresponding
    % index into the SeenMovies field
    if isa(movie_titles{iM},'char')
        if any(ismember(movie_titles{iM},'?'))
            warning('There is a question mark in the input title %s. Please verify that is not a misread character (i.e. accent)',movie_titles{iM});
        end
        title_idx = find(ismember(appended_data.SeenMovies,movie_titles(iM)));
        % if the current input is a scalar it is interpret as the index for the
        % SeenMovies field.
    elseif isa(movie_titles{iM},'double')
        title_idx = movie_titles{iM};
        warning('You provided the index referring to the movie''s title directly. It corresponds to %s',appended_data.SeenMovies{title_idx});
    end
    % initialize
    containing_pairs = zeros(length(appended_data.Pairs),1);
    
    % loop trough all the pairs to search for the title(s) you want to
    % exclude
    for iP = 1:length(appended_data.Pairs)
        title_present = ismember(appended_data.Pairs(iP,:),title_idx);
        % if the film is present in one of the two film of the current
        % pair, mark that pair
        if any(title_present)
            containing_pairs(iP,1) = 1;
        end
        title_present = [];
    end
    
    % trial indeces containing the input movie title
    containing_trials = [containing_trials find(containing_pairs==1)'];
    
    % now clear the used variables
    title_idx           =[];
    containing_pairs    =[];
    
end
fprintf('\n %d selected movie titles ',iM);
for iNames = 1:length(movie_titles)
    if isa(movie_titles{iNames},'double')
        fprintf('\n %s',appended_data.SeenMovies{movie_titles{iNames}});
    elseif isa(movie_titles{iNames},'char')
        fprintf('\n %s',movie_titles{iNames})
    end
end

fprintf('\n %d trials contain the input movie titles \n',length(containing_trials));


end