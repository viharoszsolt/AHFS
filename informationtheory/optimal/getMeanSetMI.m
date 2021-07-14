function [msmi, Eij] = getMeanSetMI(data, set, Eij)
    combs = nchoosek(1:size(set,2),2); 
    sCombs = size(combs,1);
    MIpq = zeros(1, sCombs);
    for idx = 1 : sCombs
        Fp = set(:, combs(idx,1));
        Fq = set(:, combs(idx,2));
        [MIpq(1, idx), Eij] =  getMIij(data, Fp(2,1), Fq(2,1), Eij);
    end
    
    msmi = mean(MIpq);
end