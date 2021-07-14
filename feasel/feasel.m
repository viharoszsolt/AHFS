function [FO, FD] = feasel(features, targets, varargin)
%FEASEL Summary of this function goes here
%   Detailed explanation goes here

nfeatures = size(features, 2);
ntargets = size(targets, 2);

[nfeatures, keepin, keepout, classtype] = parseargs({'nfeatures', 'keepin', 'keepout', 'classtype'}, {nfeatures, [], cell(1, ntargets), ones(1, ntargets)}, varargin);

for i = 1:ntargets
    for j = 1:size(features, 2)
        if features(:, j) == targets(:, i)
            keepout{i} = [keepout{i} j];
        end
    end
end

nkeepin = length(keepin);

FO = NaN(ntargets, nfeatures);
FD = NaN(ntargets, nfeatures);

for i = 1:ntargets
    y = targets(:, i);
    X = features;
    
    switch classtype(i)
        case 1
            occurs = 1;
            miny = min(y);
            maxy = max(y);
            diff = maxy - miny;

            while all(occurs)
                step = diff / length(occurs);
                occurs = histc(y, miny:step:maxy);
            end

            [~, y] = histc(y, miny:(diff / (length(occurs) - 2)):maxy);
        case 2
            y = kmeans(y, 10);
    end
    
    X(y < 1 | isnan(y), :) = [];
    y(y < 1 | isnan(y), :) = [];
    
    actnfea = nfeatures;
    
    if nfeatures >= size(features, 2), actnfea = size(features, 2) - length(keepout{i}); end
    
%     orig = 1:size(X, 2);
%     new = orig(~ismembc(orig, keepout{i}));
%     [features1, weights] = MI(X(:, new), y);
%     features2 = new(features1);
%     FO(i, :) = [keepin features2(1:(nfeatures-length(keepin)))];
    
    [~, history] = sequentialfs(@classmeasure, X, y, 'cv', 'none',...
                                'nfeatures', actnfea, 'keepin', keepin,...
                                'keepout', keepout{i}, 'nullmodel' , true);
                            
    for j = actnfea-nkeepin+1:-1:2
        history.In(j, :) = history.In(j, :) - history.In(j - 1, :);
    end
    
    history.In(1, :) = [];
    history.Crit(1) = [];
    
    FO(i, :) = [keepin (1:size(X, 2)) * transpose(history.In) NaN(1, nfeatures - actnfea)];
    FD(i, :) = [NaN(1, length(keepin)) 1 ./ history.Crit NaN(1, nfeatures - actnfea)];
    
    % disp('----------------------------');
    % disp(['[feasel] '  num2str(i) '. target down...']); 
end

FO(:, isnan(FO(1, :))) = [];
FD(:, isnan(FO(1, :))) = [];

end


function [criterion] = classmeasure(X, y)

% ignored = all(isnan(X), 2) | isnan(y);
% X(ignored, :) = [];
% y(ignored) = [];

if ~isempty(X) && ~all(X(:, end) == X(1, end))
    indexes = accumarray(y, transpose(1:length(y)), [], @(x){x}, {});

    [cmeanv, meanv] = detmeanvs(X, indexes);

    sbtrace = detsbtrace(indexes, cmeanv, meanv);
    swtrace = detswtrace(X, indexes, cmeanv);

    criterion = swtrace / sbtrace;
else
    criterion = Inf;
end

end


function [cmeanv, meanv] = detmeanvs(X, indexes)

k = size(indexes, 1);

cmeanv = NaN(k, size(X, 2));

for i = 1:k
    cmeanv(i, :) = nanmean(X(indexes{i}, :), 1);
end

meanv = nanmean(X, 1);
% meanv = nanmean(cmeanv, 1);

end


function [sbtrace] = detsbtrace(indexes, cmeanv, meanv)

k = size(indexes, 1);
occurs = NaN(k, 1);

for i = 1:k
    occurs(i) = length(indexes{i});
end

sbtrace = sum(sum(bsxfun(@minus, cmeanv, meanv) .^ 2, 2) .* occurs) / sum(occurs);
% sbtrace = sum(sum(bsxfun(@minus, cmeanv, meanv) .^ 2, 2)) / length(occurs);

end


function [swtrace] = detswtrace(X, indexes, cmeanv)

k = size(indexes, 1);
M = X;

for i = 1:k
    M(indexes{i}, :) = bsxfun(@minus, X(indexes{i}, :), cmeanv(i, :));
end

% swtrace = max(nansum(M .^ 2, 2));
swtrace = sum(nansum(M .^ 2, 2)) / size(X, 1);

end