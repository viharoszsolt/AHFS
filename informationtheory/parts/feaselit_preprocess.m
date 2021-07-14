function [ features, keepin, nfeatures ] = feaselit_preprocess( features, pvStruct )

    keepin = pvStruct.keepin;
    % feature-k közül kiveszem ami nem kell, illetve a targetet ha itt van
    % ha külön van, akkor nem bántom
    if ~isempty(pvStruct.keepout)
        features = features(:, 1:size(features,2)~=pvStruct.keepout);
        
        for idx = 1 : size(pvStruct.keepout, 2)
            ind = pvStruct.keepout(idx);
            keepin(pvStruct.keepin > ind) = keepin(pvStruct.keepin > ind) - 1; 
        end
    end
    
    % innentõl a target feletti indexûek egyel kevesebb indexként
    % tûnnek, végén kezelni, ellenõrizni
    nfeatures = size(features, 2);

end

