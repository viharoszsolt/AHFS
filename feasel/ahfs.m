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
% TODO  08.28: megjelenítést végzõ függvényekben le kell kezelni a keepin miatt
% nem számolt értékek hiányát. (Keepin méretû NaN sorokkal kezdõdnek)
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

% default értékek felülírása a varargin prop-value párjaival
updated = overwriteDefaults(struct(...
    'precalculated', false,...                  % temp mátrixot használjon alapértelmezetten
    'v', [],...                                 % feature nevek
    'nfeatures', 50,...                         % default
    'fn', [],...                                % feature mat fájlnév
    'tn', [],...                                % target mat fájlnév
    'ct', [],...                                % kell-e klaszterezni a targetet (1xTargetSize, egyek vagy nullák)
    'keepout', {cell(1, size(T_n_d,2))},...     % egyértelmû
    'keepin', {cell(1, size(T_n_d,2))},...      % egyértelmû
    'keepinsort', true,...                      % true-> tartsa a keepin sorrendet mindig elõrehozásnál, ezt majd törlöm mindenhonnan, felesleges kérdés, mindig tartani kell
    'skip_origc', true),...                    % anton, iris -> nem fut le az origc
    pvPairsToStruct(varargin));
CONSTS = getConsts();

% felesleges 50-ig menni kevesebb feature esetén
% Calculates the size of the result matrix according to the size of keepouts and maximum number
% of selected features, furthermore considering the targets can be parts of
% the feature matrix.
updated.nfeatures = getMatSize(D_n, T_n, updated.keepout, updated.nfeatures); 

% aktuális állapotban már kiválasztott feature-k indexei (sehol nincs eltolásos probléma vagy hívás)
already_selected = nan(size(T_n_d,2), updated.nfeatures);
% minden lépésben a legjobb modell hibája
minError = nan(size(T_n_d,2), updated.nfeatures);
% aktuális állapotban ezek az algoritmusok választották ki a legjobb modellhez tartozó legújabb jellemzõt
algorithm_chosen = cell(0, updated.nfeatures);
allT_allSel = cell(size(T_n_d,2),1);
allT_allError = cell(size(T_n_d,2),1);
allT_alg_perc_err_for_dev = cell(size(T_n_d,2),1);
cleanUpObjs = cell(size(T_n_d,2), updated.nfeatures);

% egyesével végigmegyünk a targeteken, tehát minden feasel Nx1-es targettel
% hívódik meg, tanításnál szintén
for t_ind = 1 : size(T_n_d,2)
    
    if dispFlag, disp(['==================  ' int2str(t_ind) '  =====================']); end
    
    % ugyanaz mint feljebb, csak állapotonként külön, és késõbb
    % konkatenáljuk, beillesztjük, könnyebb volt debugolni
    tmp_already_selected = nan(1, updated.nfeatures); 
    tmp_already_selected(1, 1:size(updated.keepin{t_ind},2)) = updated.keepin{t_ind};
    tmp_minError = nan(1, updated.nfeatures);
    tmp_algorithm_chosen = cell(0, updated.nfeatures);
    allSel = nan(updated.nfeatures, size(CONSTS.all_fcns_name,1));
    allError = nan(updated.nfeatures, size(CONSTS.all_fcns_name,1));
    alg_perc_err_for_dev = nan(updated.nfeatures, 3); % num of trains in eval fcn...... manuálisan
    
    % rekurziót macerásabb debuggolni, jó lesz ciklussal is (+ gyorsabb is a lefutása)
    nextInd = size(updated.keepin{t_ind},2) + 1; % 1; vegyük már figyelembe a keepint is
    while nextInd <= updated.nfeatures
        if dispFlag, disp(['[' int2str(nextInd) '] Started... ' datestr(datetime)]); tic; end

        % az algoritmus egy lépése
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
    
    % visszaillesztés, output változók feltöltése
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

% kezdéskor üres vagy elõkészíti... 
% (több targetnél lenne érdekes, jelenleg ez mindig 1x1 cell, aminek 1xN-es a tartalma)
if nextInd > 1
    keepin = create_keepin(size(T_n_d,2), already_selected(1, 1:nextInd-1), nextInd-1);
else
    keepin = cell(1, size(T_n_d,2));
end

% 9 it feasel meghatározott sorrendben
for f_ind = 1 : size(s.fcns,1)
    [FO(f_ind, :), FD(f_ind, :), cleanUpObjs{f_ind}] = s.fcns{f_ind}(D_n_d,  T_n_d,...
        'keepin', keepin,...
        'keepout', {updated.keepout{1,t_ind}},...
        'precalculated', updated.precalculated ,... % elõre kiszámolt mátrix vagy temp
        'autocleanup', false,...                    % ha van temp, használja
        'features_mat', updated.fn,...              % minden algoritmus a hozzá tartozó nevét
        'target_mat', updated.tn,...                % szintén
        'nfeatures', nextInd);                      % 1-esével
end
cleanUpObjs = cleanUpObjs{1};

% orig
f_ind = f_ind + 1;

% nincs megadva, vagy nem kell klaszterezni (default)
if isempty(updated.ct) || updated.ct(t_ind)==0
    
    % most mindig 1 oszlopos
    if size(T_n, 2) ~= 1, error('Aktuális céljellemzõ nem Nx1-es.'); end
    
    [FO(f_ind, :), FD(f_ind, :)] = feasel(D_n, T_n,...
        'keepout', {updated.keepout{1,t_ind}},...
        'keepin', keepin{1},...
        'nfeatures', nextInd,...
        'classtype', 1);
    
else % kell klaszterezni
    % itt is le kéne kezelni a több oszlopos céljellemzõt
    % sebaj, megbeszéltek szerint irisnél is approximáció, nem kell
    [FO(f_ind, :), FD(f_ind, :)] = feasel(D_n, T_n,...
        'keepout', {updated.keepout{1,t_ind}},...
        'keepin', keepin{1},...
        'nfeatures', nextInd,...
        'classtype', 2);
end

% origc
% skip anton és iris esetén
if ~updated.skip_origc
    f_ind = f_ind + 1;
    [FO(f_ind, :), FD(f_ind, :)] = feasel(D_n, T_n,...
            'keepout', {updated.keepout{1,t_ind}},...
            'keepin', keepin{1},...
            'nfeatures', nextInd,...
            'classtype', 2);
end

newF = FO(:, end);                          % aktuális lépésben az új jellemzõk
allSel = newF';                             % új debug output változó, minél egyszerûbben bõvítve a meglévõt
% newD = FD(:, end);                        % aktuális lépésben a hozzájuk tartozó mérték (most nem kell, nem konzisztens úgysem)
% uqNewF = unique(newF);                    % debughoz, nem fontos
inputs = unique(FO, 'rows');                % csak különbözõ modelleket fogunk tanítani
inputs = inputs(~any(isnan(inputs),2),:);   % NaN szûrés, ha origc-t kihagytuk

% debug, nfeatures x feaselnum, ahol az értékek a minerror
allError = nan(1, size(s.all_fcns_name,1));
    
% tanítás
E = nan(size(inputs,1), 1);
et = nan(size(inputs,1), 3); % num of trains ....... manuálisan 

% tanítási idõ
global pawn_train_time
pawn_train_time_start = datetime; 

for m_ind = 1 : size(inputs,1)
    [E(m_ind, 1), e] = evaluate_pawn(...
        D_n,...
        T_n,...                         % Nx1 a céljellemzõ mindig
        inputs(m_ind,:),...             % feature indexek a modellhez
        m_ind,...                       % csak kiíratáshoz, hogy tudjuk hol járunk épp
        size(inputs,1));                % szintén
    et(m_ind, :) = e(:,1)';
    allError(allSel == inputs(m_ind, end)) = E(m_ind);
end

% tanítási idõ szummája
pawn_train_time = pawn_train_time + (datetime - pawn_train_time_start);

% aktuális lépés eredményeinek feltöltése
[minError(1, nextInd), minIndex] = min(E);
already_selected(1, nextInd) = inputs(minIndex, end);   
algorithm_chosen{1, nextInd} = s.all_fcns_name(newF == inputs(minIndex, end));

alg_perc_err_for_dev = percentage_error(et(minIndex, :));
end

function [E, e] = evaluate_pawn(data, target, FO, ind, max_ind)
nfeas = size(FO, 2);                        % mindig csak az új konfiguráció alapján fut
E = NaN(size(FO, 1), length(nfeas));        
dispFlag = false;                            % lehetne szebben, most nem számít

for i = 1:size(FO, 1)                       % mindig 1, elhagyhatnám a for-t, most mindegy
    if dispFlag, disp(['[#' int2str(ind) '/' int2str(max_ind) ' model] Train started: ' datestr(datetime)]); end
    
    % tic;
    for j = 1:length(nfeas)
        numOfTrain = 3;                     % megbeszéltek szerint legyen inkább 3 tanításból
        e = NaN(numOfTrain, 5);             % 5 hibát dob vissza az errorcalc
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

% keepin elõállítása, most annyira nem fontos, mert mindig 1x1 cell, 
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