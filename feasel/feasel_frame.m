function [FO, FD, cleanUpObj] = feasel_frame(fun, features, targets, it_struct, varargin)

ntargets = size(targets, 2);
updated = overwriteDefaults(struct(...
    'threshold', -Inf,...
    'nfeatures', size(features, 2),...
    'keepin', {cell(1, ntargets)},...
    'keepout', {cell(1, ntargets)},...
    'isclasstype', zeros(1, ntargets),...
    'b', 0.5,...
    'features_mat', 'none',...
    'target_mat', 'none',...
    'precalculated', false,...
    'keepinsort', true,...
    'autocleanup', true,...
    'disp', false),...
    pvPairsToStruct(varargin));

featuremat_targetind = cell(1, ntargets);
for i = 1:ntargets
    for j = 1:size(features,2)
        if features(:, j) == targets(:, i)
            updated.keepout{i} = [updated.keepout{i} j];
            featuremat_targetind{i} = j;
            break;
        end
    end
end

if updated.nfeatures > size(features, 2), updated.nfeatures = size(features, 2); end;

FO = NaN(ntargets, updated.nfeatures);
FD = NaN(ntargets, updated.nfeatures);

if updated.nfeatures <= 0, return; end;

cleanUpObj = [];
if updated.precalculated
    if strcmp(updated.target_mat, 'gen')
        [fullPath_features, fullPath_target] = calcItm(features, updated.features_mat, targets, updated.target_mat, featuremat_targetind);
    else
        [fullPath_features, fullPath_target] = calcItm(features, updated.features_mat, targets, updated.target_mat);
    end
else
    [fullPath_features, fullPath_target, cleanUpObj] = tempItm(features, targets, it_struct, updated.autocleanup);
end

for i = 1:ntargets
    y = targets(:, i);
    X = features;
    
    if updated.isclasstype(i)
        occurs = 1;
        miny = min(y);
        maxy = max(y);
        diff = maxy - miny;
        
        while all(occurs)
            step = diff / length(occurs);
            occurs = histc(y, miny:step:maxy);
        end
        
        [~, y] = histc(y, miny:(diff / (length(occurs) - 2)):maxy);
    end
    
    X(y < 1 | isnan(y), :) = [];
    y(y < 1 | isnan(y), :) = [];
    
    actnfea = updated.nfeatures;
    
    if updated.nfeatures >= size(features, 2), actnfea = updated.nfeatures - length(updated.keepout{i}); end
    
    %% algorithm
    
    [FOi, FDi] = fun(X, y,...
                    'nfeatures', updated.nfeatures,...
                    'keepin', updated.keepin{i},...
                    'keepout', updated.keepout{i},...
                    'threshold', updated.threshold,...
                    'features_mat', fullPath_features,...
                    'target_mat', fullPath_target{i},...
                    'precalculated', updated.precalculated,...
                    'keepinsort', updated.keepinsort,...
                    'b', updated.b);
    
	FO(i, :) = [FOi  NaN(1, updated.nfeatures - actnfea)];
    FD(i, :) = [FDi  NaN(1, updated.nfeatures - actnfea)];
    
    if updated.disp, disp(['[' func2str(fun) '] '  num2str(i) '. target down...']); end;
end

% apply nfeatures
if updated.nfeatures <= size(FO,2)
    FO = FO(:, 1:updated.nfeatures);
    FD = FD(:, 1:updated.nfeatures);
end

if ~updated.precalculated && updated.autocleanup
    clear cleanUpObj
    cleanUpObj = [];
end

end