function [SU, Eij] = getSUij(data, Xi, Yi, Eij)
% good, 2016.07.20, feature-k között
    if Eij(Xi, Xi) == -1, Eij(Xi, Xi) = Entropy(data(:,Xi)); end;
    if Eij(Yi, Yi) == -1, Eij(Yi, Yi) = Entropy(data(:,Yi)); end;
    
    sortedIndex = sort([Xi, Yi]); % upper triangular
    if Eij(sortedIndex(1), sortedIndex(2)) == -1
        sumXY = Eij(Xi, Xi) + Eij(Yi, Yi);
        SU = 2 * ((sumXY - JointEntropy(data(:, [Xi, Yi]))) / sumXY);
        Eij(sortedIndex(1), sortedIndex(2)) = SU;
    else
        SU = Eij(sortedIndex(1), sortedIndex(2));
    end
end