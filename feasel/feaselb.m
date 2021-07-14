function [FO, FD] = feaselb(data, varargin)
%FEASEL Summary of this function goes here
%   Detailed explanation goes here

parameters = size(data, 2);
targets = 1:parameters;
nfeatures = parameters - 1;
classify = ones(parameters);

for i = 1:2:length(varargin)
    label = varargin{i};
    
    if strcmp(label, 'targets')
        targets = varargin{i+1};
    elseif strcmp(label, 'nfeatures')
        nfeatures = varargin{i+1};
    elseif strcmp(label, 'classify')
        classify = varargin{i+1};
    end
end

t = length(targets);

FO = NaN(t, nfeatures);
FD = NaN(t, nfeatures);

parfor i = 1:t
    rindexes = [1:(targets(i) - 1) (targets(i) + 1):parameters];
    y = data(:, targets(i));
    X = data(:, rindexes);
    
    if classify(i)
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
    
    [~, history] = sequentialfs(@classmeasure, X, y, 'cv', 'none',...
                                 'nfeatures', nfeatures);
    
    for j = nfeatures:-1:2
        history.In(j, :) = history.In(j, :) - history.In(j - 1, :);
    end
    
    FO(i, :) = rindexes * transpose(history.In);
    FD(i, :) = 1 ./ history.Crit;
end

end


function [criterion] = classmeasure(X, y)
%CLASSMEASURE Summary of this function goes here
%   Detailed explanation goes here

indexes = accumarray(y, transpose(1:length(y)), [], @(x){x}, {});

[cmeanv, meanv] = detmeanvs(X, indexes);

sbtrace = detsbtrace(indexes, cmeanv, meanv);
swtrace = detswtrace(X, indexes, cmeanv);

criterion = swtrace / sbtrace;

end


function [cmeanv, meanv] = detmeanvs(X, indexes)

k = size(indexes, 1);

cmeanv = NaN(k, size(X, 2));

for i = 1:k
    cmeanv(i, :) = nanmean(X(indexes{i}, :), 1);
end

meanv = mean(cmeanv);

end


function [sbtrace] = detsbtrace(indexes, cmeanv, meanv)

k = size(indexes, 1);
occurs = NaN(k, 1);

for i = 1:k
    occurs(i) = length(indexes{i});
end

sbtrace = sum(sum((bsxfun(@minus, cmeanv, meanv)) .^ 2, 2) .* occurs) / sum(occurs);

end


function [swtrace] = detswtrace(X, indexes, cmeanv)

k = size(indexes, 1);
M = X;

for i = 1:k
    M(indexes{i}, :) = bsxfun(@minus, X(indexes{i}, :), cmeanv(i, :));
end

swtrace = sum(sum(M .^ 2, 2)) / size(X, 1);

end