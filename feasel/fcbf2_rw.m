function [FO, FD, cleanUpObj] = fcbf2_rw(features, targets, varargin)

    it_struct = struct(...
        'MIij'  ,   false,...
        'SUij'  ,   true,...
        'CORRij',   false,...  
        'JMIijt',   false,...
        'SRijt' ,   false,...
        'SUit'  ,   true,...
        'MIit'  ,   false,...
        'CORRit'  ,   false);
    
    [FO, FD, cleanUpObj] = feasel_frame(@fcbf2_rw_algorithm, features, targets, it_struct, varargin{:});

end

function [FO, FD, nonFilteredInd] = fcbf2_rw_algorithm(features, target, varargin)
    
    pvStruct = pvPairsToStruct(varargin);
    m = itmManager(pvStruct.precalculated, pvStruct.features_mat, pvStruct.target_mat, features, target);
    disp('fcbf2')
    % no need to change indices for keepin or keepout.
    % target cant be the part of features matrix
    %fullPath_firstPart = getFullMatsPath();
    %load([fullPath_firstPart pvStruct.features_mat '.mat'], 'SUij');
    %load([fullPath_firstPart pvStruct.target_mat '.mat'], 'SUit');
    %load(pvStruct.features_mat, 'SUij');
    %load(pvStruct.target_mat, 'SUit');
    %nfeatures = size(SUit, 2);
    m.loadF('SUij');
    m.loadT('SUit');
    nfeatures = m.nfeatures; % size(MIit, 2);
    
    %% filter part
    
    list = zeros(2, nfeatures);
    list(1, :) = m.SUit;
    list(2, :) = 1 : nfeatures;
    list = list(:, list(1, :) >= pvStruct.threshold);
    [list, si] = feaselit_processsorted(list, pvStruct);
    keepinPart = list(:, 1:si); needsortPart = list(:, si+1:end);
    [~, d1] = sort(keepinPart(1,:),'descend');
    [~, d2] = sort(needsortPart(1,:),'descend');
    calcList = [keepinPart(:, d1), needsortPart(:, d2)]; % S'list
    
    % keepout
    if ~isempty(pvStruct.keepout)
        indices = ismember(calcList(2, :), pvStruct.keepout);
        calcList = calcList(:, ~indices);
    end

    filteredList = cell(1, 0);

    %% wrapper part
    
    slist = size(calcList,2);
    count_flag = 0; 
    endcount_flag = -1;
    stop_flag = 0;
    
    while count_flag~=endcount_flag && stop_flag ~= 1
        count_flag = endcount_flag; 
        
        % Heuristic 3
        % (starting point)
        % The feature with the largest SUic value is always a predominant feature 
        % and can be a starting point to remove other features
        Fp = calcList(:,1); 
        
        % Heuristic 1
        % A feature Fp that has already been determined to be a predominant feature
        % can always be used to filter out other features that are ranked lower than Fp 
        % and have Fp as one of its redundant peers. 
        idx = 1;
        while idx < slist && stop_flag ~= 1
            jdx = slist;
            Fq = calcList(:, jdx);
            pass = 0; 
            
            while jdx > 1 && pass ~= 1
            
                if Fp(2,1) == Fq(2,1), break; end
                
                a = Fp(2,1); b = Fq(2,1);
                if a < b, SUpq = m.getSUij(a, b); else SUpq = m.getSUij(b, a); end

                % Heuristic 2
                % For all the remaining features (from the one right next to Fp to the last one in S'list), 
                % if Fp happens to be a redundant peer to a feature Fq, Fq will be removed from S'list 
                %
                % FCBF# achieves this goal by giving every feature a temporary predominance in the elimination process 
                % and making them start eliminating features from the features which are least correlated with the class.
                % k-size subset preferred...
                if SUpq >= Fq(1,1) && ~ismember(Fq(2,1), pvStruct.keepin) % keepin
                    filteredList{1, end+1} = calcList(:, jdx); % save filtered ones
                    calcList(:, jdx) = []; % remove
                    slist = size(calcList,2);
                    jdx = slist; 
                    pass = 1;
                    count_flag = count_flag + 1;
                    if slist <= pvStruct.nfeatures, stop_flag = 1; end
                else
                    if jdx > 1, jdx = jdx - 1; Fq = calcList(:, jdx); % previous
                    else break; end
                end
            end
            
            if idx < slist, idx = idx + 1; Fp = calcList(:, idx); % next
            else break; end
        end
    end

    %% post-process 
    
    nonFilteredInd = slist;
    bestList = [calcList, cell2mat(filteredList)];
    FO = bestList(2, :);
    FD = bestList(1, :);
    
    % apply nfeatures
    if pvStruct.nfeatures <= size(FO,2)
        FO = FO(:, 1:pvStruct.nfeatures);
        FD = FD(:, 1:pvStruct.nfeatures);
    end
    
    
     %beszurtam ezt a sort!!!!!!!!!!!!!!
    FO(1, 1:end-1) = sort(FO(1, 1:end-1));
    % disp(['[FCBF#] redundancy-filtered features after index: ' num2str(nonFilteredInd)]);
    
end