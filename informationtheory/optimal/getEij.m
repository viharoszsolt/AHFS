function [Eij, Ei, Et] = getEij(features, target, JEij, varargin)
% Entropy and Mutual Information Matrix
% Eij   : felsõ háromszög mátrixban az i. és j. változó kölcsönös információja 
%         diagonálisban az i. változó és a target kölcsönös entrópiája
% Ei    : változók entrópiája
% Et    : target entrópiája
%
% features - feature mátrix
% varargin - adathalmaz azonosító fájlból való betöltéshez
%   'dataset' opcionális
%   pl:
%   'dataset', 'none' - kiszámolja elölrõl az egészet
%   'dataset', 'd_opel_10' - ha megtalálja a d_opel_10.mat fájlt, betölti, s nem számolja ki a mátrixot
%                            ha nem találja meg: kiszámolja elölrõl az egészet

updated = overwriteDefaults(struct(...
    'dataset', 'none'),...
    pvPairsToStruct(varargin));

if ~strcmp(updated.dataset, 'none') && exist([updated.dataset '.mat'], 'file') == 2
    S = whos('-file', [updated.dataset '.mat']);
    for k = 1 : length(S)
        if strcmp(S(k).name, 'Eij')
            % feltételezzük, hogy azért szerepel Eij az adott fájlban, mert
            % ez a függvény generálta, így biztos lesz Ei és Et része is.
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
    