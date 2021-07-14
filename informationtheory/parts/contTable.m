function ct = contTable(input)
    n = size(input, 2);
    cinput = cell(1, n);
    for i = 1 : n
        cinput{1, i} = input(:,i); end
    ct = crosstab(cinput{:});
end

