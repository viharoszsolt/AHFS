function JEij = getJEij(features, target, varargin)
% Joint Entropy Matrix
% fels� h�romsz�g m�trixban az i. �s j. v�ltoz� egy�ttes entr�pi�ja
% diagon�lisban az i. v�ltoz� �s a target egy�ttes entr�pi�ja
%
% features - feature m�trix
% varargin - adathalmaz azonos�t� f�jlb�l val� bet�lt�shez
%   'dataset' opcion�lis
%   pl:
%   'dataset', 'none' - kisz�molja el�lr�l az eg�szet
%   'dataset', 'd_opel_10' - ha megtal�lja a d_opel_10.mat f�jlt, bet�lti, s nem sz�molja ki a m�trixot
%                            ha nem tal�lja meg: kisz�molja el�lr�l az eg�szet

updated = overwriteDefaults(struct(...
    'dataset', 'none'),...
    pvPairsToStruct(varargin));

if ~strcmp(updated.dataset, 'none') && exist([updated.dataset '.mat'], 'file') == 2
     S = whos('-file', [updated.dataset '.mat']);
    for k = 1 : length(S)
        if strcmp(S(k).name, 'JEij')
            load(updated.dataset, 'JEij');
            return;
        end
    end
end

nfeatures = size(features, 2);
JEij = -ones(nfeatures);

tempJE = zeros(1, nfeatures);
parfor idx = 1 : nfeatures
    tempJE(idx) = JointEntropy([features(:,idx), target]);
end

for idx = 1 : nfeatures
    JEij(idx, idx) = tempJE(idx);
end
clear tempJE

uti = nchoosek(1:nfeatures, 2); % upper triangular indices
tempJEij = zeros(size(uti,1), 3);
for idx = 1 : size(uti, 1) % parfor �rdekes, a features-nek nagy az overheadje
    tempJEij(idx, :) = [uti(idx,1), uti(idx,2), JointEntropy([features(:, uti(idx, 1)), features(:, uti(idx, 2))])]; 
end

for idx = 1 : size(tempJEij, 1)
    JEij(tempJEij(idx, 1), tempJEij(idx, 2)) = tempJEij(idx,3);
end

if ~strcmp(updated.dataset, 'none') && exist([updated.dataset '.mat'], 'file') == 2
    save(updated.dataset, 'JEij', '-append');
else 
    save(updated.dataset, 'JEij');
end

end
    