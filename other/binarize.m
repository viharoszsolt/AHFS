function [R] = binarize(V)
%BINARIZE Summary of this function goes here
%   Detailed explanation goes here

elements = unique(V);

% if length(elements) == 2
%     R = V == elements(2);
% else
    R = zeros(size(V, 1), size(elements, 2));

    for i = 1:length(elements)
        R(:, i) = V == elements(i);
    end
% end

end

