function msmi = getMeanSetMI_rw(combs, set, m)
    sCombs = size(combs,1);
    MIpq = zeros(1, sCombs);
    for idx = 1 : sCombs
        Fp_ind = set(2, combs(idx,1));
        Fq_ind = set(2, combs(idx,2));
        if Fp_ind < Fq_ind, c = m.getMIij(Fp_ind, Fq_ind); else c = m.getMIij(Fq_ind, Fp_ind); end 
        MIpq(1, idx) = c;
    end
    
    msmi = mean(MIpq);
end