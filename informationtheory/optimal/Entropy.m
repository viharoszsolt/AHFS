function H = Entropy(ddata)
% good, 2016.07.20
% ddata - Nx1 vector

H = JointEntropy2V(ddata, ddata);

% frequency = histcounts(ddata);
% 
% % Calculate sample class probabilities
% pvec = frequency / sum(frequency);
% 
% ppvec = pvec(pvec>0);
% H = sum(-ppvec.*log2(ppvec));
    
end