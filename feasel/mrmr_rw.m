function [FO, FD, cleanUpObj] = mrmr_rw(features, targets, varargin)

    it_struct = struct(...
        'MIij'  ,   true,...
        'SUij'  ,   false,...
        'CORRij',   false,...  
        'JMIijt',   false,...
        'SRijt' ,   false,...
        'SUit'  ,   false,...
        'MIit'  ,   true,...
        'CORRit'  ,   false);
    

    [FO, FD, cleanUpObj] = feasel_frame(@mrmr_rw_algorithm, features, targets, it_struct, varargin{:});

end

function [FO, FD] = mrmr_rw_algorithm(features, target, varargin)
    
    pvStruct = pvPairsToStruct(varargin);
    m = itmManager(pvStruct.precalculated, pvStruct.features_mat, pvStruct.target_mat, features, target);
    disp('mrmr')
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
        combs = nchoosek(1:mes_ind+1,2);
        for num = 1 : n
            tmpList = [aktList(:,1:mes_ind), calcList(:, num)];
            msmi = getMeanSetMI_rw(combs, tmpList, m);
            ss(1, num) = mean(tmpList(1,:))/msmi;
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