classdef Model < handle
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = public)
        model;
        ioroles;
        error;
    end
    
    methods (Abstract)
        build(this, data, ioroles, varargin);
        
        instance = create(this, data, ioroles, varargin);
        output = apply(this, input);
        [output, error] = evaluate(this, data);
    end
    
end

