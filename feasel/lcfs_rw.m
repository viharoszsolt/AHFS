function [FO, FD, cleanUpObj] = lcfs_rw(features, targets, varargin)

    it_struct = struct(...
        'MIij'  ,   false,...
        'SUij'  ,   false,...
        'CORRij',   true,...  
        'JMIijt',   false,...
        'SRijt' ,   false,...
        'SUit'  ,   false,...
        'MIit'  ,   false,...
        'CORRit'  ,   true);

    [FO, FD, cleanUpObj] = feasel_frame(@lcfs_rw_algorithm, features, targets, it_struct, varargin{:});

end

function [FO, FD] = lcfs_rw_algorithm(features, target, varargin)
    disp('lcfs')
    pvStruct = pvPairsToStruct(varargin);
    m = itmManager(pvStruct.precalculated, pvStruct.features_mat, pvStruct.target_mat, features, target);
    
    % no need to change indices for keepin or keepout.
    % target cant be the part of features matrix
    %fullPath_firstPart = getFullMatsPath();
    %load([fullPath_firstPart pvStruct.features_mat '.mat'], 'CORRij');
    %load([fullPath_firstPart pvStruct.target_mat '.mat'], 'CORRit');
    % load(pvStruct.features_mat, 'CORRij');
    % load(pvStruct.target_mat, 'CORRit');
    % nfeatures = size(CORRit, 2);
    m.loadF('CORRij');
    m.loadT('CORRit');
    nfeatures = m.nfeatures; % size(MIit, 2);
    
%     %% modify correlation for the algorithm
%     
%     % positive or negative correlations are equally good
%     % NaN values (consts) and 0 means the same thing -> no corr
%     CORRit(isnan(CORRit)) = 0;
%     CORRit = abs(CORRit);       % [0 1] bigger the better
%     CORRij(isnan(CORRij)) = 0;
%     CORRij = abs(CORRij);       % [0 1] bigger the better
%     
    %% filter part
    
    list = zeros(2, nfeatures);
    list(1, :) = modify_CORR_value_for_algorithm(m.CORRit);
    list(2, :) = 1 : nfeatures;
    list = list(:, list(1, :) >= pvStruct.threshold);
    [list, si] = feaselit_processsorted(list, pvStruct);
    keepinPart = list(:, 1:si); needsortPart = list(:, si+1:end);
    [~, d1] = sort(keepinPart(1,:),'descend');
    [~, d2] = sort(needsortPart(1,:),'descend');
    calcList = [keepinPart(:, d1), needsortPart(:, d2)]; % S'list
    
    %% wrapper part
    
    stop_flag = 0;
    % ha a keepin-t belesz�molva �s a keepout-ot kiz�rva a marad�k felhaszn�lhat�
    % feature-k sz�ma kevesebb mint az elv�rt nfeatures, akkor hozz�igaz�tjuk az nfeatures �rt�k�t
    calcSize = size(keepinPart,2) + (size(needsortPart,2) - size(pvStruct.keepout,2));
    if calcSize < pvStruct.nfeatures
        pvStruct.nfeatures = calcSize; end
    aktList = nan(2, pvStruct.nfeatures);
    mes = nan(1, size(aktList,2));
    
    % keepout, keepin
    [calcList, aktList, mes, mes_ind] = feaselit_processargs(calcList, aktList, mes, pvStruct);
    
    % algorithm
    while ~isempty(calcList) && stop_flag ~= 1
        n = size(calcList,2);
        ss = zeros(1, n);
        for num = 1 : n
            % ss(1, num) = lcfs_criterion(aktList(:,1:mes_ind), calcList(:, num), CORRij, pvStruct.b);
            ss(1, num) = lcfs_criterion(aktList(:,1:mes_ind), calcList(:, num), m, pvStruct.b);
        end
        mes_ind = mes_ind + 1;
        [mes(mes_ind) , maxInd] = max(ss);
        aktList(:, mes_ind) = calcList(:, maxInd);
        calcList(:, maxInd) = [];
        
        if mes_ind >= pvStruct.nfeatures, stop_flag = 1; end
    end

    %% post-process 
    
    bestList = aktList;
    FO = bestList(2, 1:pvStruct.nfeatures);
    FD = mes(1, 1:pvStruct.nfeatures);
    
    
     %beszurtam ezt a sort!!!!!!!!!!!!!!
    FO(1, 1:end-1) = sort(FO(1, 1:end-1));
    
end

function CORR = modify_CORR_value_for_algorithm(CORR)
    CORR(isnan(CORR)) = 0;
    CORR = abs(CORR);       % [0 1] bigger the better
end

function measure = lcfs_criterion(S, Fp, m, b)
    % ha a b = 0, akkor csak az �ppen vizsg�lt feature �s a target class
    % k�zti line�ris korrel�ci�s egy�tthat�j�t maximaliz�lja
    % ha a b = 1, akkor a kiv�lasztott jellemz�k �tlagos line�ris korrel�ci�s egy�tthat�j�t haszn�lja fel
    % tesztelve cikkben 0.5 illetve 1 k�z�tti �rt�kekkel tetsz�legesen, hogy mennyire legyen figyelembe v�ve...
    
    sumCORR = 0;
    sS = size(S, 2);
    for idx = 1 : sS
        a = S(2,idx);
        b = Fp(2,1);
        if a < b, c = m.CORRij(a, b); else c = m.CORRij(b, a); end
        c = modify_CORR_value_for_algorithm(c);
        sumCORR = sumCORR + c;
    end
    measure = Fp(1,1) - (b / sS) * sumCORR;
end

% function measure = lcfs_criterion(S, Fp, CORRij, b)
%     % ha a b = 0, akkor csak az �ppen vizsg�lt feature �s a target class
%     % k�zti line�ris korrel�ci�s egy�tthat�j�t maximaliz�lja
%     % ha a b = 1, akkor a kiv�lasztott jellemz�k �tlagos line�ris korrel�ci�s egy�tthat�j�t haszn�lja fel
%     % tesztelve cikkben 0.5 illetve 1 k�z�tti �rt�kekkel tetsz�legesen, hogy mennyire legyen figyelembe v�ve...
%     
%     sumCORR = 0;
%     sS = size(S, 2);
%     for idx = 1 : sS
%         a = S(2,idx);
%         b = Fp(2,1);
%         if a < b, c = CORRij(a, b); else c = CORRij(b, a); end
%         sumCORR = sumCORR + c;
%     end
%     measure = Fp(1,1) - (b / sS) * sumCORR;
% end