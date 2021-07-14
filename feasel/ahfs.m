function [already_selected, algorithm_chosen, minError, ...
    allT_allSel, allT_allError, allT_alg_perc_err_for_dev] = ahfs(D_n, D_n_d, T_n, T_n_d, varargin)
% PAWN ALGORITHM
% Custom feature selection method 
% based on multiple feature selection methods, and ANN model building.
%
% INPUT
% --------------------------------
% D_n : feature matrix, can be discrete or continous
% D_n_d : feature matrix, only discrete, if D_n is discrete, D_n = D_n_d
% T_n : target matrix, can be discrete or continous,
% T_n_d : target matrix, only discrete, if T_n is discrete, T_n = T_n_d
% varargin : property-value pairs, see "updated" struct at line 34.
%
% OUTPUT
% --------------------------------
% already_selected : FO
% algorithm_chosen : Algorithm names in every step
% minError : FD, error values
% allT_allSel : partial results of algorithm names
% allT_allError : partial results of errors in train phase
% allT_alg_perc_err_for_dev : partial results of errors, percentage error for deviation
%
% Keepin test 08.28 Housing
% ahfs(D_n(:, 1:13), D_n_d(:, 1:13), D_n(:, 14), D_n_d(:, 14), 'ct', 1, 'nfeatures', 5)
% ans = [13 6 5 10 1]
% ahfs(D_n(:, 1:13), D_n_d(:, 1:13), D_n(:, 14), D_n_d(:, 14), 'ct', 1, 'nfeatures', 5, 'keepin', {[2 7 8]})
% ans = [2 7 8 13 6]
%
% TODO  08.28: megjelen�t�st v�gz� f�ggv�nyekben le kell kezelni a keepin miatt
% nem sz�molt �rt�kek hi�ny�t. (Keepin m�ret� NaN sorokkal kezd�dnek)
%

% debughoz
dispFlag = true;

% timestamp
clearvars -global pawn_train_time pawn_feasel_time
clear mex
global pawn_train_time
global pawn_feasel_time
pawn_feasel_time = datetime;
pawn_train_time = 0;

if dispFlag, disp(['pawn started at: ' datestr(datetime)]); end

% default �rt�kek fel�l�r�sa a varargin prop-value p�rjaival
updated = overwriteDefaults(struct(...
    'precalculated', false,...                  % temp m�trixot haszn�ljon alap�rtelmezetten
    'v', [],...                                 % feature nevek
    'nfeatures', 50,...                         % default
    'fn', [],...                                % feature mat f�jln�v
    'tn', [],...                                % target mat f�jln�v
    'ct', [],...                                % kell-e klaszterezni a targetet (1xTargetSize, egyek vagy null�k)
    'keepout', {cell(1, size(T_n_d,2))},...     % egy�rtelm�
    'keepin', {cell(1, size(T_n_d,2))},...      % egy�rtelm�
    'keepinsort', true,...                      % true-> tartsa a keepin sorrendet mindig el�rehoz�sn�l, ezt majd t�rl�m mindenhonnan, felesleges k�rd�s, mindig tartani kell
    'skip_origc', true),...                    % anton, iris -> nem fut le az origc
    pvPairsToStruct(varargin));
CONSTS = getConsts();

% felesleges 50-ig menni kevesebb feature eset�n
% Calculates the size of the result matrix according to the size of keepouts and maximum number
% of selected features, furthermore considering the targets can be parts of
% the feature matrix.
updated.nfeatures = getMatSize(D_n, T_n, updated.keepout, updated.nfeatures); 

% aktu�lis �llapotban m�r kiv�lasztott feature-k indexei (sehol nincs eltol�sos probl�ma vagy h�v�s)
already_selected = nan(size(T_n_d,2), updated.nfeatures);
% minden l�p�sben a legjobb modell hib�ja
minError = nan(size(T_n_d,2), updated.nfeatures);
% aktu�lis �llapotban ezek az algoritmusok v�lasztott�k ki a legjobb modellhez tartoz� leg�jabb jellemz�t
algorithm_chosen = cell(0, updated.nfeatures);
allT_allSel = cell(size(T_n_d,2),1);
allT_allError = cell(size(T_n_d,2),1);
allT_alg_perc_err_for_dev = cell(size(T_n_d,2),1);
cleanUpObjs = cell(size(T_n_d,2), updated.nfeatures);

% egyes�vel v�gigmegy�nk a targeteken, teh�t minden feasel Nx1-es targettel
% h�v�dik meg, tan�t�sn�l szint�n
for t_ind = 1 : size(T_n_d,2)
    
    if dispFlag, disp(['==================  ' int2str(t_ind) '  =====================']); end
    
    % ugyanaz mint feljebb, csak �llapotonk�nt k�l�n, �s k�s�bb
    % konkaten�ljuk, beillesztj�k, k�nnyebb volt debugolni
    tmp_already_selected = nan(1, updated.nfeatures); 
    tmp_already_selected(1, 1:size(updated.keepin{t_ind},2)) = updated.keepin{t_ind};
    tmp_minError = nan(1, updated.nfeatures);
    tmp_algorithm_chosen = cell(0, updated.nfeatures);
    allSel = nan(updated.nfeatures, size(CONSTS.all_fcns_name,1));
    allError = nan(updated.nfeatures, size(CONSTS.all_fcns_name,1));
    alg_perc_err_for_dev = nan(updated.nfeatures, 3); % num of trains in eval fcn...... manu�lisan
    
    % rekurzi�t macer�sabb debuggolni, j� lesz ciklussal is (+ gyorsabb is a lefut�sa)
    nextInd = size(updated.keepin{t_ind},2) + 1; % 1; vegy�k m�r figyelembe a keepint is
    while nextInd <= updated.nfeatures
        if dispFlag, disp(['[' int2str(nextInd) '] Started... ' datestr(datetime)]); tic; end

        % az algoritmus egy l�p�se
        [tmp_already_selected, tmp_algorithm_chosen,...
            tmp_minError, tmp_allSel, tmp_allError, ...
            tmp_alg_perc_err_for_dev, cleanUpObjs{t_ind, nextInd}] = nextState(D_n, D_n_d, T_n(:,t_ind), T_n_d(:,t_ind),...
            updated,...
            tmp_already_selected,...
            tmp_algorithm_chosen,...
            tmp_minError,...
            nextInd,...
            t_ind);

        allSel(nextInd, :) = tmp_allSel;
        allError(nextInd, :) = tmp_allError;
        alg_perc_err_for_dev(nextInd, :) = tmp_alg_perc_err_for_dev;
        
        if dispFlag, disp(['[' int2str(nextInd) '] Finished after ' int2str(toc) ' seconds.']);  end
        nextInd = nextInd + 1;
        
    end
    
    % visszailleszt�s, output v�ltoz�k felt�lt�se
    already_selected(t_ind, :) = tmp_already_selected;
    algorithm_chosen = [algorithm_chosen; tmp_algorithm_chosen];
    minError(t_ind, :) = tmp_minError;
    allT_allSel{t_ind,1} = allSel;
    allT_allError{t_ind,1} = allError;
    allT_alg_perc_err_for_dev{t_ind,1} = alg_perc_err_for_dev;
end

pawn_feasel_time = (datetime - pawn_feasel_time) - pawn_train_time;

end

function [already_selected, algorithm_chosen, minError, allSel, allError, alg_perc_err_for_dev, cleanUpObjs] = nextState(D_n, D_n_d, T_n, T_n_d,...
    updated, already_selected, algorithm_chosen, minError, nextInd, t_ind)

% konstansok.... a feasel nevek miatt kellett, mindegy, nem zavarnak 1 sorban
s = getConsts();
FO = nan(size(s.fcns,1)+1, nextInd);
FD = nan(size(s.fcns,1)+1, nextInd);
cleanUpObjs = cell(size(s.fcns,1), 1);

% kezd�skor �res vagy el�k�sz�ti... 
% (t�bb targetn�l lenne �rdekes, jelenleg ez mindig 1x1 cell, aminek 1xN-es a tartalma)
if nextInd > 1
    keepin = create_keepin(size(T_n_d,2), already_selected(1, 1:nextInd-1), nextInd-1);
else
    keepin = cell(1, size(T_n_d,2));
end

% 9 it feasel meghat�rozott sorrendben
for f_ind = 1 : size(s.fcns,1)
    [FO(f_ind, :), FD(f_ind, :), cleanUpObjs{f_ind}] = s.fcns{f_ind}(D_n_d,  T_n_d,...
        'keepin', keepin,...
        'keepout', {updated.keepout{1,t_ind}},...
        'precalculated', updated.precalculated ,... % el�re kisz�molt m�trix vagy temp
        'autocleanup', false,...                    % ha van temp, haszn�lja
        'features_mat', updated.fn,...              % minden algoritmus a hozz� tartoz� nev�t
        'target_mat', updated.tn,...                % szint�n
        'nfeatures', nextInd);                      % 1-es�vel
end
cleanUpObjs = cleanUpObjs{1};

% orig
f_ind = f_ind + 1;

% nincs megadva, vagy nem kell klaszterezni (default)
if isempty(updated.ct) || updated.ct(t_ind)==0
    
    % most mindig 1 oszlopos
    if size(T_n, 2) ~= 1, error('Aktu�lis c�ljellemz� nem Nx1-es.'); end
    
    [FO(f_ind, :), FD(f_ind, :)] = feasel(D_n, T_n,...
        'keepout', {updated.keepout{1,t_ind}},...
        'keepin', keepin{1},...
        'nfeatures', nextInd,...
        'classtype', 1);
    
else % kell klaszterezni
    % itt is le k�ne kezelni a t�bb oszlopos c�ljellemz�t
    % sebaj, megbesz�ltek szerint irisn�l is approxim�ci�, nem kell
    [FO(f_ind, :), FD(f_ind, :)] = feasel(D_n, T_n,...
        'keepout', {updated.keepout{1,t_ind}},...
        'keepin', keepin{1},...
        'nfeatures', nextInd,...
        'classtype', 2);
end

% origc
% skip anton �s iris eset�n
if ~updated.skip_origc
    f_ind = f_ind + 1;
    [FO(f_ind, :), FD(f_ind, :)] = feasel(D_n, T_n,...
            'keepout', {updated.keepout{1,t_ind}},...
            'keepin', keepin{1},...
            'nfeatures', nextInd,...
            'classtype', 2);
end

newF = FO(:, end);                          % aktu�lis l�p�sben az �j jellemz�k
allSel = newF';                             % �j debug output v�ltoz�, min�l egyszer�bben b�v�tve a megl�v�t
% newD = FD(:, end);                        % aktu�lis l�p�sben a hozz�juk tartoz� m�rt�k (most nem kell, nem konzisztens �gysem)
% uqNewF = unique(newF);                    % debughoz, nem fontos
inputs = unique(FO, 'rows');                % csak k�l�nb�z� modelleket fogunk tan�tani
inputs = inputs(~any(isnan(inputs),2),:);   % NaN sz�r�s, ha origc-t kihagytuk

% debug, nfeatures x feaselnum, ahol az �rt�kek a minerror
allError = nan(1, size(s.all_fcns_name,1));
    
% tan�t�s
E = nan(size(inputs,1), 1);
et = nan(size(inputs,1), 3); % num of trains ....... manu�lisan 

% tan�t�si id�
global pawn_train_time
pawn_train_time_start = datetime; 

for m_ind = 1 : size(inputs,1)
    [E(m_ind, 1), e] = evaluate_pawn(...
        D_n,...
        T_n,...                         % Nx1 a c�ljellemz� mindig
        inputs(m_ind,:),...             % feature indexek a modellhez
        m_ind,...                       % csak ki�rat�shoz, hogy tudjuk hol j�runk �pp
        size(inputs,1));                % szint�n
    et(m_ind, :) = e(:,1)';
    allError(allSel == inputs(m_ind, end)) = E(m_ind);
end

% tan�t�si id� szumm�ja
pawn_train_time = pawn_train_time + (datetime - pawn_train_time_start);

% aktu�lis l�p�s eredm�nyeinek felt�lt�se
[minError(1, nextInd), minIndex] = min(E);
already_selected(1, nextInd) = inputs(minIndex, end);   
algorithm_chosen{1, nextInd} = s.all_fcns_name(newF == inputs(minIndex, end));

alg_perc_err_for_dev = percentage_error(et(minIndex, :));
end

function [E, e] = evaluate_pawn(data, target, FO, ind, max_ind)
nfeas = size(FO, 2);                        % mindig csak az �j konfigur�ci� alapj�n fut
E = NaN(size(FO, 1), length(nfeas));        
dispFlag = false;                            % lehetne szebben, most nem sz�m�t

for i = 1:size(FO, 1)                       % mindig 1, elhagyhatn�m a for-t, most mindegy
    if dispFlag, disp(['[#' int2str(ind) '/' int2str(max_ind) ' model] Train started: ' datestr(datetime)]); end
    
    % tic;
    for j = 1:length(nfeas)
        numOfTrain = 3;                     % megbesz�ltek szerint legyen ink�bb 3 tan�t�sb�l
        e = NaN(numOfTrain, 5);             % 5 hib�t dob vissza az errorcalc
        for k = 1:numOfTrain 
            model = ANN2();
            model.build([data(:, FO(i, 1:nfeas(j))) target(:, i)], [-ones(1, nfeas(j)) 1]);
            [~, e(k, :)] = model.evaluate([data(:, FO(i, 1:nfeas(j))) target(:, i)]);
        end
        E(i, j) = (min(e(:, 1)) / ((0.8 ^ 2) / 2)) ^ 0.5;
    end
    % toc;
end

end

% keepin el��ll�t�sa, most annyira nem fontos, mert mindig 1x1 cell, 
% benne 1xN-es keepin vektorral
function keepin = create_keepin(n, FO, limit)

keepin = cell(1, n);
for idx = 1:n
    keepin{idx} = FO(idx, 1:limit);
end

end

function value = getMatSize(features, targets, keepout, nfeatures)
% Calculates the size of the result matrix according to the size of keepouts and maximum number
% of selected features, furthermore, considering the targets can be parts of
% the feature matrix.
%
% features: feature matrix - NxM double (N:nat, M:nat)
% targets: target matrix - NxK double (K:nat)
% keepout: keepout feature indices - 1xK cell with 1xL double values (L:nat [0..M])
% 

ntargets = size(targets,2);
assert(ntargets>0,'[E] Target matrix is empty.');
assert(size(keepout, 2)==ntargets,'[E] Bad keepout size.');

for i = 1 : ntargets
    for j = 1 : size(features,2)
        if features(:, j) == targets(:, i)
            keepout{i} = [keepout{i} j];
            break;
        end
    end
end

keepoutSizes = cellfun(@(x) size(x, 2), keepout); 

calcSize = size(features,2) - max(keepoutSizes);

if calcSize < nfeatures
    value = calcSize; 
else
    value = nfeatures;
end

end

function s = getConsts()
    
    s = struct();

    s.fcns = {
      @fcbf_rw;
      @fcbf2_rw;
      @ffsa_rw;
      @lcfs_rw;
      @mmifs_rw;
      @mrmr_rw;
      @mrmr2_rw;
      @nmifs_rw;
%       @jmim_rw;
%       @njmim_rw
    };

    s.all_fcns_name = {
      'fcbf';
      'fcbf2';
      'ffsa';
      'lcfs';
      'mmifs';
      'mrmr';
      'mrmr2';
      'nmifs'
%       'jmim';
%       'njmim';
      'orig';
%      'origc';
    };
end