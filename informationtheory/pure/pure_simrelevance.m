function SR = pure_simrelevance(X, Y, C)

    SR = pure_JointMutualInformation(X, Y, C) / JointEntropy([X, Y, C]);

end