function ClusterMask = Extract_cluster_mask(cfg,stat)

% ClusterMask = Extract_cluster_mask(cfg,stat)
%
% Extract_cluster_mask is used to create a logical
% mask for the positive/negative cluster number cfg.ClusterNb.
%
% INPUT:
%   - cfg       = structure with fields
%       - cfg.posnegCluster = string, either 'positive' or 'negative'
%                             indicating whether the cluster to consider is
%                             positive or negative.
%       - cfg.ClusterNb     = scalar, indicating the number of the cluster
%                             to consider
%   - stat      = structure from either ft_timelockstatistics or
%                 ft_freqstatistics
%
% DA 2018/02/20

% Check that the cfg structure has the correct fieldsname
if ~isfield(cfg,'posnegCluster')
    error(' You should provide cfg structure with the field  ''posnegCluster''');
elseif ~isfield(cfg,'ClusterNb')
    error(' You should provide cfg structure with the field  ''ClusterNb''');
end

ClusterMask = zeros(size(stat.prob));

if strcmp(cfg.posnegCluster,'positive')
    ClusterMask(stat.posclusterslabelmat==cfg.ClusterNb) = 1;
    fprintf('\n Creatign mask for POSITIVE cluster n. %02d',cfg.ClusterNb); 
elseif strcmp(cfg.posnegCluster,'negative')
    ClusterMask(stat.negclusterslabelmat==cfg.ClusterNb) = 1;
    fprintf('\n Creatign mask for NEGATIVE cluster n. %02d',cfg.ClusterNb); 

else
    fprintf('\n cfg.posnegCluster has to be a string (either ''positive'' or ''negative'')');
end


ClusterMask = logical(ClusterMask); 
return

end