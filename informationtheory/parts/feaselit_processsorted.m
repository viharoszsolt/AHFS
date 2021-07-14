function [list, si] = feaselit_processsorted(list, pvStruct)

si = 0;
if ~isempty(pvStruct.keepin)
    indices = ismember(list(2, :), pvStruct.keepin); % logical, not sorted
    list = [list(:,indices), list(:, ~indices)];
    si = size(pvStruct.keepin, 2);
end

end

