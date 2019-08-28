function [b,pfitd] = logreg_lapse(x,y,flink)
%  LOGREG_LAPSE  Fit logisitic regression model with lapse rate

% check input arguments
if nargin < 3
    flink = 'prbit';
end
if nargin < 2 || size(x,1) ~= size(y,1)
    error('mismatching input dimensions!');
end

% ensure logical response array
y = logical(y);

% fit logistic regression model
options = optimset('Display','off');
b = fminsearch(@(p)-get_llh(p),zeros(size(x,2)+1,1),options);

% compute best-fitting response probabilities
y(:) = 1;
[~,pfitd] = get_llh(b);

% reparameterize lapse rate in [0,1]
b(end) = 1/(1+exp(-b(end)));

    function [llh,pr] = get_llh(p)
        % columnize parameter list
        p = p(:);
        % compute decision variable
        dv = (x*p(1:end-1)).*(y*2-1);
        % compute response probabilities
        switch flink
            case 'logit' % logit
                pr = 1./(1+exp(-dv));
            case 'prbit' % probit
                pr = normcdf(dv);
        end
        % reparameterize lapse rate in [0,1]
        p(end) = 1/(1+exp(-p(end)));
        % take lapse rate into account
        pr = pr*(1-p(end))+0.5*p(end);
        % compute log-likelihood from clipped response probabilities
        llh = sum(log(max(pr,realmin)));
    end

end