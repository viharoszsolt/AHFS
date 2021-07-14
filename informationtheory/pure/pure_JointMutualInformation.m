function JMI = pure_JointMutualInformation(X, Y, C)

    JMI = Entropy(C) - (JointEntropy([X, Y, C]) - JointEntropy([X, Y]));

end