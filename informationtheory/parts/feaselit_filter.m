function [ list, feature_entropy ] = feaselit_filter(wrapper, Et, target, nfeatures)
%FEASELIT_FILTER Summary of this function goes here
%   Detailed explanation goes here

list = -ones(2, nfeatures);
feature_entropy = -ones(1, nfeatures);

parfor idx = 1 : nfeatures
    features = wrapper.Value;
    feature_entropy(idx) = Entropy(features(:, idx));
    MI = feature_entropy(idx) + Et - JointEntropy([features(:, idx) target]);
    % Eit(idx) = MI;
    
    list(:, idx) = [MI; idx];
end
        
end

