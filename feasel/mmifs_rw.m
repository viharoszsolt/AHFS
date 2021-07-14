function [FO, FD, cleanUpObj] = mmifs_rw(features, targets, varargin) %M�t�: FO, FD egy-egy sorvektor lesz 
    %disp('mmifs-t h�vom');
    it_struct = struct(...
        'MIij'  ,   true,...
        'SUij'  ,   false,...
        'CORRij',   false,...  
        'JMIijt',   false,...
        'SRijt' ,   false,...
        'SUit'  ,   false,...
        'MIit'  ,   true,...
        'CORRit'  ,   false);
    

    [FO, FD, cleanUpObj] = feasel_frame(@mmifs_rw_algorithm, features, targets, it_struct, varargin{:});

end

function [FO, FD] = mmifs_rw_algorithm(features, target, varargin)
    
    pvStruct = pvPairsToStruct(varargin);
    m = itmManager(pvStruct.precalculated, pvStruct.features_mat, pvStruct.target_mat, features, target);
    disp('mmifs')
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
%     disp('mmifs-ben list indul:');
%     disp(list);
    list = list(:, list(1, :) >= pvStruct.threshold);
    [list, si] = feaselit_processsorted(list, pvStruct); %M�t�: kiv�logatjuk �s el�rehozzuk a list�ban azokat a feature�ket, amelyek szerepelnek a keepinben
%     disp('mmifs-ben list rendezve:');
%     disp(list);
    keepinPart = list(:, 1:si); needsortPart = list(:, si+1:end); %M�t�: ennek megfelel�en kett�szedj�k a listet
    [~, d1] = sort(keepinPart(1,:),'descend');
    [~, d2] = sort(needsortPart(1,:),'descend');
    calcList = [keepinPart(:, d1), needsortPart(:, d2)]; % S'list
%     disp('mmifs-ben calclist indul:');
%     disp(calcList);
  
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
            ss(1, num) = mmifs_criterion(m, aktList(:,1:mes_ind), calcList(:, num), pvStruct.b);
        end
        %disp('mmifs-ben ss:');
        %disp(ss);
       
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

function measure = mmifs_criterion(m, S, Fp, b)%M�t�: b="beta"
    % ha a b = 0, akkor csak az �ppen vizsg�lt feature �s a target class
    % k�zti k�lcs�n�s inform�ci�t maximaliz�lja
    % ha a b = 1, akkor a kiv�lasztott jellemz�k �tlagos k�lcs�n�s inform�ci�j�t haszn�lja fel
    % tesztelve cikkben 0.5 illetve 1 k�z�tti �rt�kekkel tetsz�legesen, hogy mennyire legyen figyelembe v�ve...
    
    sumMI = 0;
    sS = size(S, 2);
    for idx = 1 : sS
        a_ind = S(2,idx);
        b_ind = Fp(2,1);
        if a_ind < b_ind, c = m.getMIij(a_ind, b_ind);  else
            c = m.getMIij(b_ind, a_ind); end %M�t�: fels�h�romsz�g m�trix, teh�t vigy�zni kell, nehogy NaN-ba �tk�zz�nk
        sumMI = sumMI + c;
    end
    measure = Fp(1,1) - (b / sS) * sumMI;
end