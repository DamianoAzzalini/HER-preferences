function [beta, cst, res] = My_glm(data,regressors, flagZscore)
%
%  CTB 27-Nov-2013
%  Modified March 2016 (MBR)
%  Modified October 2017 (DA): added squeeze in lines 70 & 71
%  Modified April 2018 (DA): compute residuals and cst only if nargout > 1
%                            (speed up computation for sources).
%----------------------------------------------------------------
%
%  Computes the beta (coefficient of linear regression)
%
%   input:
% - data organized as Repetitions X Time samples X Sensors
% with Repetitions corresponding to trials (or heartbeats)
% - regressors organized as Repetitions X Regressor Numbers
% - flagZscore  0 or 1 to zscore data by sensors or not
%
%
%   output:
% - beta: matrix with betas, organized as NbRegressors X Time samples X Sensors
% - cst: intercept, organized as 1 x Time samples x Sensors
% - res: residuals, organized as trials x time samples x sensors
%
%



%Checking input parameters
if (nargin ~= 3) error('Not the right number input parameters.'); end
if (flagZscore ~= 0 && flagZscore ~= 1) error('flag Zscore should be 0 or 1'); end


nbRepet=size(data,1);
nbSample=size(data,2);
nbSensor=size(data,3);
nbRegressor=size(regressors,2);

if (size(regressors,1) ~= nbRepet) error('mismatch in matrix dimensions'); end

%Calcul

beta=zeros(nbRegressor,nbSample,nbSensor);
reg=[ones(nbRepet,1),regressors]; %on ajoute le terme constant a la design matrix)
disp(['Size regressors: ' num2str(size(reg))])
disp(['Size data: ' num2str(size(data))])

if flagZscore==1
    data=zscore(data); %zscore across repetitions, separately for each time bin and each sensor
end

beta=pinv(reg)*reshape(data,nbRepet,[]);  %en entree on ne garde que la struct repetition, tt le reste est concatene
beta=reshape(beta,size(regressors,2)+1,nbSample, nbSensor);

% Get intercept
cst = beta(1, :, :);

% Get betas
beta=beta(2:end,:,:);

%%%%%%%%%%%% CHANGED IT FOR SOURCE GLM, OTHERWISE TOO SLOW %%%%%%%%%%%%
% Compute this output only if asked
if nargout>2
    res = zeros(nbRepet, nbSample, nbSensor);
    for t = 1:nbSample
        for chan = 1:nbSensor
            for itrial = 1:nbRepet
                res(itrial, t, chan) = data(itrial, t, chan) - cst(1, t, chan);
                for iregress = 1:size(beta, 1)
                    res(itrial, t, chan) = res(itrial, t, chan) - beta(iregress, t, chan) * regressors(itrial, iregress);
                end
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Squeeze intercept and betas (in case you've singleton dimension)
cst     = squeeze(cst);
% Squeeze intercept and betas (in case you've singleton dimension)
beta    = squeeze(beta);

