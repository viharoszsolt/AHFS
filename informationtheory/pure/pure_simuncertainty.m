function SU = pure_simuncertainty(X, Y)
    SU = 2 * (mutualinfo([X Y]) / (Entropy(X) + Entropy(Y)));
end