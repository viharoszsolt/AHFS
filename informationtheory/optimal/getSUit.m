function [SU, Eij, Eit] = getSUit(data, Xi, t, Et, Eij, Eit)
% good, 2016.07.20, feature-k között
% Et - target vektor entropiaja
% Eit - adott feature a targethez képest
    if Eij(Xi, Xi) == -1, Eij(Xi, Xi) = Entropy(data(:,Xi)); end;
    
    if Eit(Xi) == -1
        sumXT = Eij(Xi, Xi) + Et;
        SU = 2 * ((sumXT - JointEntropy([data(:, Xi) t])) / sumXT);
        Eit(Xi) = SU;
    else
        SU = Eit(Xi);
    end
end