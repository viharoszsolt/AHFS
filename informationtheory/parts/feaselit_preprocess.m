function [ features, keepin, nfeatures ] = feaselit_preprocess( features, pvStruct )

    keepin = pvStruct.keepin;
    % feature-k k�z�l kiveszem ami nem kell, illetve a targetet ha itt van
    % ha k�l�n van, akkor nem b�ntom
    if ~isempty(pvStruct.keepout)
        features = features(:, 1:size(features,2)~=pvStruct.keepout);
        
        for idx = 1 : size(pvStruct.keepout, 2)
            ind = pvStruct.keepout(idx);
            keepin(pvStruct.keepin > ind) = keepin(pvStruct.keepin > ind) - 1; 
        end
    end
    
    % innent�l a target feletti index�ek egyel kevesebb indexk�nt
    % t�nnek, v�g�n kezelni, ellen�rizni
    nfeatures = size(features, 2);

end

