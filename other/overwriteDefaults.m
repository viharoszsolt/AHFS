function options = overwriteDefaults(defaults, userDefined)

    if isstruct(defaults) && isstruct(userDefined)
        fieldsDefaults = fields(userDefined);
        fieldsUserDefined = fields(defaults);
        nFieldsDefaults = numel(fieldsDefaults);
        nFieldsUserDefined = numel(fieldsUserDefined);

        for actualDefaultInd = 1:nFieldsDefaults
            actualDefault = fieldsDefaults{actualDefaultInd};
            found = false;

            for actualUserDefinedInd =1:nFieldsUserDefined
                actualUserDefined = fieldsUserDefined{actualUserDefinedInd};
                if strcmp(actualDefault, actualUserDefined)
                    found = true;
                    defaults.(actualUserDefined) = userDefined.(actualDefault);
                end
            end

            if ~found
                defaults.(actualDefault) = userDefined.(actualDefault);
            end

        end
    end

    options = defaults;

end