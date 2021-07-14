function pStruct = pvPairsToStruct(pvPairs)

    narginchk(1, 1);

    validateattributes(pvPairs,...
                       {'cell'},...
                       {});

    assert(rem(length(pvPairs),2) == 0,...
           'Unbalanced pv pair array');

    pStruct = struct;

    for i = 1:2:length(pvPairs)  
        propertyName = lower(pvPairs{i});
        propertyValue = pvPairs{i+1};
        pStruct.(propertyName) = propertyValue;
    end

end


