function JH = JointEntropyMV(data, ind, buckets, solo)
% data - diszkretizalt adathalmaz
% ind - jellemzo indexei
% buckets - szetvalasztas elotti csoportok
% solo - 1 erteket tartalmazo csoportok darabszama
% JH = jh_rec(dcutting, [2 5 7], {})
% 
% for variables: n >= 3
% for variables: n < 3 : 
    
    if length(ind) == 1
        JH = Entropy(data(:, ind));
        return;
    end

    if isempty(buckets)
        solo = 0;
        nBins = length(unique(data(:,1)));
        buckets = cell(nBins, 1);
        for jdx = 1 : nBins
            buckets{jdx, 1} = find(data(:, ind(1)) == jdx); end;
    end

    dividedBuckets = cell(0,1);
    for idx = 1 : size(buckets(:,1), 1)
        if size(buckets{idx, 1}, 1) > 1
            alphabet = unique(data(buckets{idx, 1}, ind(2)));
            div = cell(size(alphabet, 1), 1);
            for symbol = 1:length(alphabet)
                div{symbol,1} = buckets{idx, 1}(data(buckets{idx, 1}, ind(2)) == alphabet(symbol), :); end
            dividedBuckets = vertcat(dividedBuckets, div);
        end
        
    end
    
    soloInd = cell2mat(cellfun(@(x) (size(x,1)==1), dividedBuckets, 'UniformOutput', false));
    dividedBuckets(soloInd) = []; solo = solo + sum(soloInd);
    
    ind(2) = [];
    if length(ind) > 1 && ~isempty(dividedBuckets)
        JH = JointEntropyMV(data, ind, dividedBuckets, solo);
    else
        ct = cell2mat(cellfun(@(x) (size(x,1)), dividedBuckets, 'UniformOutput', false));
        jpt = ct ./ (sum(ct)+solo); pjpt = jpt(jpt>0);
        jh = @(x) sum(-x.*log2(x));
        JH = jh(pjpt) + jh(ones(solo, 1)./(sum(ct)+solo));
    end
end
