function [calcList, aktList, mes, mes_ind] = feaselit_processargs(calcList, aktList, mes, pvStruct)

% keepout
if ~isempty(pvStruct.keepout)
    indices = ismember(calcList(2, :), pvStruct.keepout);
    calcList = calcList(:, ~indices);
end

% keepin
if isempty(pvStruct.keepin)
    aktList(:, 1) = calcList(:, 1);
    calcList(:, 1) = [];
    
    mes(1) = aktList(1, 1);
    mes_ind = 1;
else
    indices = 1:size(pvStruct.keepin,2); 
    li = calcList(:, indices);
    if pvStruct.keepinsort
        % inner sort
        sl = calcList(:, indices);
        li = zeros(2, size(pvStruct.keepin,2));
        for idx = 1 : size(pvStruct.keepin,2)
            li(:, idx) = sl(:, ismember(sl(2,:), pvStruct.keepin(idx))); end
    end
    
    aktList(:, indices) = li;
    calcList(:, indices) = [];
    
    for idx = 1 : size(pvStruct.keepin, 2)
        mes(idx) = aktList(1, idx); end
    mes_ind = size(pvStruct.keepin, 2);
end

end