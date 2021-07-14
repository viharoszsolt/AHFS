classdef ANN2 < Model
    %ANN Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function build(this, data, ioroles, varargin)
            this.model = feedforwardnet(8);
            this.model.layers{1}.transferFcn = 'logsig';
            this.model.layers{2}.transferFcn = 'logsig';
            this.model.inputs{1}.processParams{2}.ymin = 0.1;
            this.model.inputs{1}.processParams{2}.ymax = 0.9;
            this.model.outputs{2}.processParams{2}.ymin = 0.1;
            this.model.outputs{2}.processParams{2}.ymax = 0.9;
            
            if length(varargin) > 1
                for i = 1:2:length(varargin)
                    if strcmp(varargin{i}, 'divideFcn')
                        this.model.divideFcn = varargin{i+1};
                    end
                end
            end
            
%             this.model.divideParam.trainRatio = 0.85;
%             this.model.divideParam.valRatio = 0.15;
%             this.model.divideParam.testRatio = 0;
%             this.model.trainParam.epochs = 1000;
            this.model.trainParam.showWindow = false;
%             this.model.trainParam.lr = 0.01;
            this.ioroles = ioroles;

            input = data(:, ioroles == -1);
            output = data(:, ioroles == 1);
            
            this.model = train(this.model, transpose(input), transpose(output), 'useParallel', 'no');

            [~, this.error] = this.evaluate(data);
        end
        
        function instance = create(this, data, ioroles, varargin)
            instance = ANN2();
            instance.build(data, ioroles, varargin);
        end
        
        function output = apply(this, input)
            output = transpose(this.model(transpose(input)));
        end
        
        function [output, error] = evaluate(this, data)
            output = this.apply(data(:, this.ioroles == -1));
            error = errorcalc(output, data(:, this.ioroles == 1));
        end
    end
    
end

