classdef itmManager < matlab.mixin.SetGet
    
    properties (Access = private)
        prepT
        prepF
    end
    
    properties
        precalculated
        features_mat
        target_mat
        features
        target
    end
    
    properties (Dependent)
        nfeatures
    end
    
    % target spec
    properties
        Et              % part of sth - full
        JEit            % part of sth - full
        MIit            % full
        SUit            % full
        CORRit          % full
        JEijt
        JMIijt
        SRijt
    end
    
    % feature spec
    properties
        Ei              % part of sth - full
        JEij            % part of sth - full            
        MIij
        SUij
        CORRij          
    end
    
    methods
        function this = itmManager(precalculated, features_mat, target_mat, features, target)
            this.precalculated = precalculated;
            this.features_mat = features_mat;
            this.target_mat = target_mat;
            this.features = features;
            this.target = target;
            this.prepT = false;
            this.prepF = false;
            
            s = load(this.features_mat, 'Ei', 'JEij');
            this.fillProperties(s);
            
            s = load(this.target_mat, 'Et', 'JEit', 'JEijt');
            this.fillProperties(s);
        end
        
        function loadT(this, varargin)
            s = load(this.target_mat, varargin{:});
            this.fillProperties(s);
            this.prepT = true;
        end
        
        function loadF(this, varargin)
            s = load(this.features_mat, varargin{:});
            this.fillProperties(s);
            this.prepF = true;
        end
    end
    
    methods
        function value = get.nfeatures(this)
            if ~isempty(this.MIit)
                value = size(this.MIit,2);
            elseif ~isempty(this.SUit)
                value = size(this.SUit,2);
            elseif ~isempty(this.CORRit)
                value = size(this.CORRit,2);
            else
                error('E:undefined data');
            end
        end
    end
    
    methods % getters for feature spec matrices
        function value = getMIij(this, i, j)
            l = this.prepF && ~isempty(this.MIij);
            
            if this.precalculated && l
                value = this.MIij(i,j);
                return;
            elseif l
                if isnan(this.MIij(i, j))
                    % Ei + Ej
                    sumEij = this.Ei(i) + this.Ei(j);

                    % JEij
                    if isnan(this.JEij(i,j))
                        je2 = JointEntropy([this.features(:, i), this.features(:, j)]);
                        this.JEij(i,j) = je2;
                        
                        % save
                        JEij = this.JEij;
                        save(this.features_mat, 'JEij', '-append');
                    else
                        je2 = this.JEij(i,j);
                    end 

                    % MIij
                    mi = sumEij - je2;
                    this.MIij(i,j) = mi;
                    
                    % save
                    MIij = this.MIij;
                    save(this.features_mat, 'MIij', '-append');
                end
                
                value = this.MIij(i,j);
                return;
            else
                error('E: Invalid usage. Probably missing loadF or loadT method call.');
            end   
        end
        
        function value = getSUij(this, i, j)
            l = this.prepF && ~isempty(this.SUij);
            
            if this.precalculated && l
                value = this.SUij(i,j);
                return;
            elseif l
                if isnan(this.SUij(i, j))
                    % Ei + Ej
                    sumEij = this.Ei(i) + this.Ei(j);

                    % JEij
                    if isnan(this.JEij(i, j))
                        je2 = JointEntropy([this.features(:, i), this.features(:, j)]);
                        this.JEij(i,j) = je2;
                        
                        % save
                        JEij = this.JEij;
                        save(this.features_mat, 'JEij', '-append');
                    else
                        je2 = this.JEij(i,j);
                    end

                    % MIij
                    su = 2 * ((sumEij - je2) / sumEij);
                    this.SUij(i,j) = su;
                    
                    % save
                    SUij = this.SUij;
                    save(this.features_mat, 'SUij', '-append');
                end
                
                value = this.SUij(i,j);
                return;
            else
                error('E: Invalid usage. Probably missing loadF or loadT method call.');
            end   
        end
        
        function value = getCORRij(this, i, j)
            l = this.prepF && ~isempty(this.CORRij);
            
            if this.precalculated && l
                value = this.CORRij(i,j);
                return;
            elseif l
                if isnan(this.CORRij(i, j))
                    c = corrcoef([this.features(:, i), this.features(:, j)]);
                    corr = c(2, 1);
                    this.CORRij(i,j) = corr;
                    
                    % save
                    CORRij = this.CORRij;
                    save(this.features_mat, 'CORRij', '-append');
                end
                
                value = this.CORRij(i,j);
                return;
            else
                error('E: Invalid usage. Probably missing loadF or loadT method call.');
            end   
        end
    end
    
    methods % getters for target spec matrices
        function value = getMIit(this, i)
            if this.prepT && ~isempty(this.MIit)
                value = this.MIit(i);
                return;
            else
                error('E: Invalid usage. Probably missing loadF or loadT method call.');
            end
        end
        
        function value = getSUit(this, i)
            if this.prepT && ~isempty(this.MIit)
                value = this.SUit(i);
                return;
            else
                error('E: Invalid usage. Probably missing loadF or loadT method call.');
            end
        end
        
        function value = getCORRit(this, i)
            if this.prepT && ~isempty(this.MIit)
                value = this.CORRit(i);
                return;
            else
                error('E: Invalid usage. Probably missing loadF or loadT method call.');
            end
        end
        
        function value = getJMIijt(this, i, j)
            l = this.prepT && ~isempty(this.JMIijt);
            
            if this.precalculated && l
                value = this.JMIijt(i,j);
                return;
            elseif l
                jmi = this.updateJMIijt(i, j);
                    
                value = jmi;
                return;
            else
                error('E: Invalid usage. Probably missing loadF or loadT method call.');
            end   
        end
        
        function value = getSRijt(this, i, j)
            l = this.prepT && ~isempty(this.SRijt);
            
            if this.precalculated && l
                value = this.SRijt(i,j);
                return;
            elseif l
                sr = this.updateSRijt(i, j);
                
                value = sr;
                return;
            else
                error('E: Invalid usage. Probably missing loadF or loadT method call.');
            end 
        end
        
    end
    
    methods (Access = private)
        function fillProperties(this, s)
            fields = fieldnames(s);
            for idx = 1 : numel(fields)
                this.(fields{idx}) = s.(fields{idx}); end
        end
        
        function value = updateJMIijt(this, i, j)
            
            % JEijt
            if isnan(this.JEijt(i, j))
                je3 = JointEntropy([this.features(:, i), this.features(:, j), this.target]);
                this.JEijt(i,j) = je3;
                
                % save 
                JEijt = this.JEijt;
                save(this.target_mat, 'JEijt', '-append');
            else
                je3 = this.JEijt(i,j);
            end
            
            if isnan(this.JEij(i, j))
                je2 = JointEntropy([this.features(:, i), this.features(:, j)]);
                this.JEij(i,j) = je2;
                
                % save 
                JEij = this.JEij;
                save(this.features_mat, 'JEij', '-append');
            else
                je2 = this.JEij(i,j);
            end
            
            if isnan(this.JMIijt(i, j))
                % JMIijt
                jmi = this.Et - (je3 - je2);
                this.JMIijt(i,j) = jmi;
                
                % save 
                JMIijt = this.JMIijt;
                save(this.target_mat, 'JMIijt', '-append');
            else
                jmi = this.JMIijt(i,j);
            end
                
            value = jmi;
        end
        
        function value = updateSRijt(this, i, j)
            
            if isnan(this.SRijt(i, j))
                JMIijt = updateJMIijt(this, i, j);
                JEijt = this.JEijt(i,j);

                sr = JMIijt / JEijt;
                this.SRijt(i,j) = sr;

                % save
                SRijt = this.SRijt;
                save(this.target_mat, 'SRijt', '-append');
            else
                sr = this.SRijt(i, j);
            end
            
            value = sr;
        end
    end
    
end