function [output, normparam] = normalizer(input, varargin)

if length(varargin) == 1
    normparam = zeros(2, size(input, 2));
    
    minimum = nanmin(input);
    maximum = nanmax(input);

    normparam(1, :) = (minimum * varargin{1}(2) - maximum * varargin{1}(1)) / (varargin{1}(2) - varargin{1}(1));
    normparam(2, :) = varargin{1}(2) ./ (maximum - normparam(1, :));
    
    output = bsxfun(@times, bsxfun(@minus, input, normparam(1, :)), normparam(2, :));
elseif length(varargin) == 2
    if varargin{2} == 'a'
        output = bsxfun(@times, bsxfun(@minus, input, varargin{1}(1, :)), varargin{1}(2, :));
    elseif varargin{2} == 'r'
        output = bsxfun(@plus, bsxfun(@rdivide, input, varargin{1}(2, :)), varargin{1}(1, :));
    end
end

end

