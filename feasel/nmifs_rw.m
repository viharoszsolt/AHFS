function [FO, FD, cleanUpObj] = nmifs_rw(features, targets, varargin) %M�t�: FO, FD egy-egy sorvektor lesz 

    it_struct = struct(...
        'MIij'  ,   true,...
        'SUij'  ,   false,...
        'CORRij',   false,...  
        'JMIijt',   false,...
        'SRijt' ,   false,...
        'SUit'  ,   false,...
        'MIit'  ,   true,...
        'CORRit'  ,   false);
    

    [FO, FD, cleanUpObj] = feasel_frame(@nmifs_rw_algorithm, features, targets, it_struct, varargin{:});

end

function [FO, FD] = nmifs_rw_algorithm(features, target, varargin)
    
    pvStruct = pvPairsToStruct(varargin);
    m = itmManager(pvStruct.precalculated, pvStruct.features_mat, pvStruct.target_mat, features, target);
    disp('nmifs')
    % no need to change indices for keepin or keepout.
    % target cant be the part of features matrix
    %fullPath_firstPart = getFullMatsPath();
    %load([fullPath_firstPart pvStruct.features_mat '.mat'], 'MIij');
    %load([fullPath_firstPart pvStruct.target_mat '.mat'], 'MIit');
    %load(pvStruct.features_mat, 'MIij');
    %load(pvStruct.target_mat, 'MIit');
    %nfeatures = size(MIit, 2);
    m.loadF('MIij');
    m.loadT('MIit');
    nfeatures = m.nfeatures; % size(MIit, 2);
    
    %% 
    
    list = zeros(2, nfeatures);
    list(1, :) = m.MIit;
    list(2, :) = 1 : nfeatures;
    %list = list(:, list(1, :) >= pvStruct.threshold);
    [list, si] = feaselit_processsorted(list, pvStruct);
    keepinPart = list(:, 1:si); needsortPart = list(:, si+1:end);
    [~, d1] = sort(keepinPart(1,:),'descend');
    [~, d2] = sort(needsortPart(1,:),'descend');
    calcList = [keepinPart(:, d1), needsortPart(:, d2)]; % S'list
    
    %% 
    
    stop_flag = 0;
   
    % feature-k sz�ma kevesebb mint az elv�rt nfeatures, akkor hozz�igaz�tjuk az nfeatures �rt�k�t
    calcSize = size(keepinPart,2) + (size(needsortPart,2) - size(pvStruct.keepout,2));
    if calcSize < pvStruct.nfeatures
        pvStruct.nfeatures = calcSize; end
    aktList = nan(2, pvStruct.nfeatures);
    mes = nan(1, size(aktList,2));
    
    % keepout, keepin
    [calcList, aktList, mes, mes_ind] = feaselit_processargs(calcList, aktList, mes, pvStruct);
    %disp('mmifs-ben calclist csonk�tva:')
    %disp(calcList);
    %disp('mmifs-ben aktlist indul:');
    %disp(aktList);
    % algorithm
    while ~isempty(calcList) && stop_flag ~= 1
        n = size(calcList,2);
        ss = zeros(1, n);
        for num = 1 : n
            ss(1, num) = nmifs_criterion(m, aktList(:,1:mes_ind), calcList(:, num), pvStruct.b);
        end
        mes_ind = mes_ind + 1;
        [mes(mes_ind) , maxInd] = max(ss);
        aktList(:, mes_ind) = calcList(:, maxInd);
%         disp('nmifs-ben aktlist �p�l:');
%         disp(aktList);
%         calcList(:, maxInd) = [];
%         disp('nmifs-ben calclist bont�dik:');
%         disp(calcList);
        if mes_ind >= pvStruct.nfeatures, stop_flag = 1; end
    end

    %% post-process 
    
    bestList = aktList;
    FO = bestList(2, 1:pvStruct.nfeatures);
    FD = mes(1, 1:pvStruct.nfeatures);
    
     %beszurtam ezt a sort!!!!!!!!!!!!!!
    FO(1, 1:end-1) = sort(FO(1, 1:end-1));
end

function measure = nmifs_criterion(m, S, Fp, b)%M�t�: b="beta"
    % ha a b = 0, akkor csak az �ppen vizsg�lt feature �s a target class
    % k�zti k�lcs�n�s inform�ci�t maximaliz�lja
    % ha a b = 1, akkor a kiv�lasztott jellemz�k �tlagos k�lcs�n�s inform�ci�j�t haszn�lja fel
    % tesztelve cikkben 0.5 illetve 1 k�z�tti �rt�kekkel tetsz�legesen, hogy mennyire legyen figyelembe v�ve...
    
    sumMI_norm = 0;
    sS = size(S, 2);
    for idx = 1 : sS
        a_ind = S(2,idx);
        b_ind = Fp(2,1);
        if a_ind < b_ind, c = m.getMIij(a_ind, b_ind); else c = m.getMIij(b_ind, a_ind); end
        min_entropy=min(m.Ei(a_ind), m.Ei(b_ind));
        sumMI_norm = sumMI_norm + c/min_entropy;
    end
    measure = Fp(1,1) - (1 / sS) * sumMI_norm;
end