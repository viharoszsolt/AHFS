function JH = JointEntropy(X)

n = size(X,2);
if n <= 0, error('Invalid argument'); end;

switch n
    case 1
        JH = Entropy(X);
        
    case 2 
        JH = JointEntropy2V(X(:,1),X(:,2));
        
    otherwise
        JH = JointEntropyMV(X, 1:n, {});
end

end