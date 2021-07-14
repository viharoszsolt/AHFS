function [varargout] = parseargs(keys, defaults, args)
%PARSEARGS Summary of this function goes here
%   Detailed explanation goes here

varargout = cell(1, nargout);

for i = 1:2:length(args)
    label = args{i};
    
    for j = 1:nargout
        if strcmp(label, keys{j})
            varargout{j} = args{i+1};
        end
    end
end

for i = 1:nargout
    if isempty(varargout{i})
        varargout{i} = defaults{i};
    end
end

end

