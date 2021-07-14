function jpt = probTable(ct)
    marginalVar1 = sum(ct, 1);
    % marginalVar2 = sum(ct, 2);
    % if sum(marginalVar1) ~= sum(marginalVar2), error('Sum of marginal distributions are not equal'); end
    jpt = ct ./ sum(marginalVar1);
end

