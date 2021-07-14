function [FO, FD, cleanUpObj] = njmim_rw(features, targets, varargin)

    it_struct = struct(...
        'MIij'  ,   true,...
        'SUij'  ,   false,...
        'CORRij',   false,...  
        'JMIijt',   false,...
        'SRijt' ,   false);
    
    [FO, FD, cleanUpObj] = feasel_frame(@njmim_rw_algorithm, features, targets, it_struct, varargin{:});

end

function [FO, FD] = njmim_rw_algorithm(features, target, varargin)
    
    pvStruct = pvPairsToStruct(varargin);
    m = itmManager(pvStruct.precalculated, pvStruct.features_mat, pvStruct.target_mat, features, target);
    
    % no need to change indices for keepin or keepout.
    % target cant be the part of features matrix
    %fullPath_firstPart = getFullMatsPath();
    % load([fullPath_firstPart pvStruct.features_mat '.mat']);
    %load([fullPath_firstPart pvStruct.target_mat '.mat'], 'MIit', 'SRijt');
    %load(pvStruct.target_mat, 'MIit', 'SRijt');
    %nfeatures = size(MIit, 2);
    m.loadT('MIit', 'JMIijt', 'SRijt');
    nfeatures = m.nfeatures; % size(MIit, 2);
    
    %% filter part
    
    list = zeros(2, nfeatures);
    list(1, :) = m.MIit;
    list(2, :) = 1 : nfeatures;
    list = list(:, list(1, :) >= pvStruct.threshold);
    [list, si] = feaselit_processsorted(list, pvStruct);
    keepinPart = list(:, 1:si); needsortPart = list(:, si+1:end);
    [~, d1] = sort(keepinPart(1,:),'descend');
    [~, d2] = sort(needsortPart(1,:),'descend');
    calcList = [keepinPart(:, d1), needsortPart(:, d2)]; % S'list
    
    %% wrapper part
    
    stop_flag = 0;
    % ha a keepin-t beleszámolva és a keepout-ot kizárva a maradék felhasználható
    % feature-k száma kevesebb mint az elvárt nfeatures, akkor hozzáigazítjuk az nfeatures értékét
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
            njmi = getSetSR(aktList(:,1:mes_ind),calcList(:, num), m);
            ss(1, num) = njmi;
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
    
end

function minNJMI = getSetSR(set, Fi, m)
    sSet = size(set, 2);
    NJMIpqc = zeros(1, sSet);
    Fi_ind = Fi(2,1);
    for idx = 1 : sSet
        Fp_ind = set(2, idx);
        if Fp_ind < Fi_ind, c = m.getSRijt(Fp_ind, Fi_ind); else c = m.getSRijt(Fi_ind, Fp_ind); end % upper triangular
        NJMIpqc(1, idx) = c;
    end
    
    minNJMI = min(NJMIpqc);
end