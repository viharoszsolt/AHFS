function ddata = discretize(data, bins)
    if nargin < 2, bins = 3; end;

    [n, dim] = size(data);
    ddata = zeros(n, dim);
    for i = 1:dim
       ddata(:, i)= doDiscretize(data(:, i), bins); end
    ddata = ddata+1;
end

function dvec = doDiscretize(vec, bins)
    svec = sort(vec);
    dvec = vec;

    pos = svec(round(length(vec) / bins * [1:bins]));
    for j = 1:length(vec)
        dvec(j) = sum(vec(j) > pos); end
end