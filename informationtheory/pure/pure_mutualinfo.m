function MI = pure_mutualinfo( input )
% input : nx2 double

    MI = Entropy(input(:,1)) + Entropy(input(:,2)) - JointEntropy(input);
end

