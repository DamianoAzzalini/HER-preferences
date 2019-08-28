function [b,pfitd,mle,aic] = logreg(x,y,flink)
%  LOGREG  Fit logistic regression model

% check input arguments
if nargin < 3
    flink = 'prbit';
end
if nargin < 2 || size(x,1) ~= size(y,1)
    error('mismatching input dimensions!');
end

nobs = size(x,1); % number of observations
nfit = size(x,2); % number of fitted parameters

% ensure logical response array
y = logical(y);

% fit logistic regression model
options = optimset('Display','off');
b = fminsearch(@(p)-get_llh(p),zeros(size(x,2),1),options);

% compute best-fitting response probabilities
pfitd = x*b(:);
switch flink
    case 'logit' % logit
        pfitd = 1./(1+exp(-pfitd));
    case 'prbit' % probit
        pfitd = normcdf(pfitd);
end

mle = get_llh(b); % Maximum Likelihood Estimate
aic = -2*mle+2*nfit+2*nfit*(nfit+1)/(nobs-nfit+1); % Akaike Information Criterion

    function [llh] = get_llh(p)
        % compute decision variable
        dv = (x*p(:)).*(y*2-1);
        % compute response probabilities
        switch flink
            case 'logit' % logit
                pr = 1./(1+exp(-dv));
            case 'prbit' % probit
                pr = normcdf(dv);
        end
        % compute log-likelihood from clipped response probabilities
        llh = sum(log(max(pr,realmin)));
    end

end