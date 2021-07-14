function [FO, FD, cleanUpObj] = mrmr2_rw(features, targets, varargin)
% d_opel_20 dataset, 1 target
% Elapsed time is 387.543795 seconds. 
% Elapsed time is 101.706257 seconds. 
% Elapsed time is 95.935 seconds. 
% Elapsed time is 68.463483 seconds. # now, parfor

% precalculated parfor
% Elapsed time is 72.983390 seconds.
% Elapsed time is 61.901770 seconds.
% then Elapsed time is 7.690530 seconds.

    it_struct = struct(...
        'MIij'  ,   true,...
        'SUij'  ,   false,...
        'CORRij',   false,...  
        'JMIijt',   false,...
        'SRijt' ,   false,...
        'SUit'  ,   false,...
        'MIit'  ,   true,...
        'CORRit'  ,   false);
    

    [FO, FD, cleanUpObj] = feasel_frame(@mrmr2_rw_algorithm, features, targets, it_struct, varargin{:});

end

function [FO, FD] = mrmr2_rw_algorithm(features, target, varargin)
    
    pvStruct = pvPairsToStruct(varargin);
    m = itmManager(pvStruct.precalculated, pvStruct.features_mat, pvStruct.target_mat, features, target);
    disp('mrmr2')
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
    [~, d1] = sort(keepinPart(1,:),'descend'); % resort by default, keepin_sort later
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
    
    % teszteset: nfeatures m�r el�rve a legelej�n, pl nfeatures = 1
    % nem kell bel�pni a ciklusba.
    % teszteset: nfeatures m�r el�rve a legelej�n, pl nfeatures = 1
    % �s a keepin pl 2 elem�. Ekkor a keepin-es v�ltoz�kat sorbarakja a
    % m�rt�ke szerint, �s visszat�r annyival, amennyi az nfeatures
    if mes_ind >= pvStruct.nfeatures
        stop_flag = 1;
        aktList = aktList(:, 1:pvStruct.nfeatures);
        mes = mes(:, 1:pvStruct.nfeatures);
    end
    
    % algorithm
    while ~isempty(calcList) && stop_flag ~= 1
        n = size(calcList,2);
        ss = zeros(1, n);
        combs = nchoosek(1:mes_ind+1,2);
        for num = 1 : n
            tmpList = [aktList(:,1:mes_ind), calcList(:, num)];
            mR = redundancy_criterion_rw(combs, tmpList, m);
            MR = mean(tmpList(1, :));
            ss(1, num) = MR - mR;
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

function mR = redundancy_criterion_rw(combs, set, m)
    sCombs = size(combs,1);
    MIpq = zeros(1, sCombs);
    for idx = 1 : sCombs
        Fp_ind = set(2, combs(idx,1));
        Fq_ind = set(2, combs(idx,2));
        if Fp_ind < Fq_ind, c = m.getMIij(Fp_ind, Fq_ind); else c = m.getMIij(Fq_ind, Fp_ind); end 
        MIpq(1, idx) = c;
    end
    
    mR = sum(MIpq) / (size(MIpq, 2) ^ 2);
end