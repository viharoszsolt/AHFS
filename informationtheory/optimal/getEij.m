function [Eij, Ei, Et] = getEij(features, target, JEij, varargin)
% Entropy and Mutual Information Matrix
% Eij   : fels� h�romsz�g m�trixban az i. �s j. v�ltoz� k�lcs�n�s inform�ci�ja 
%         diagon�lisban az i. v�ltoz� �s a target k�lcs�n�s entr�pi�ja
% Ei    : v�ltoz�k entr�pi�ja
% Et    : target entr�pi�ja
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
        if strcmp(S(k).name, 'Eij')
            % felt�telezz�k, hogy az�rt szerepel Eij az adott f�jlban, mert
            % ez a f�ggv�ny gener�lta, �gy biztos lesz Ei �s Et r�sze is.
            load(updated.dataset, 'Eij', 'Ei', 'Et');
            return;
        end
    end
end
    
nfeatures = size(features, 2);
Eij = -ones(nfeatures);
Ei = nan(1, nfeatures);

for idx = 1 : nfeatures
    Ei(idx) = Entropy(features(:, idx));
end
Et = Entropy(target);

for idx = 1 : nfeatures
    sumXY = Ei(idx) + Et;
    Eij(idx, idx) = sumXY - JEij(idx, idx); % MI
end

uti = nchoosek(1:nfeatures, 2); % upper triangular indices
for idx = 1 : size(uti, 1)
    sumXY = Ei(uti(idx, 1)) + Ei(uti(idx, 2));
    Eij(uti(idx, 1), uti(idx, 2)) = sumXY - JEij(uti(idx, 1), uti(idx, 2)); % MI
end

if ~strcmp(updated.dataset, 'none') && exist([updated.dataset '.mat'], 'file') == 2
    save(updated.dataset, 'Eij', 'Ei', 'Et', '-append');
else 
    save(updated.dataset, 'Eij', 'Ei', 'Et');
end

end
    