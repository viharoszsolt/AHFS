function [fullPath_features, fullPath_target] = calcItm(features, features_mat, target, target_mat, varargin)
% examples
% --------
% single target:
% calcItm(d_opel_10, 'd_opel_10', t_opel(:,7), 't_opel');
% calcItm(d_cutting_10(:,1:8), 'd_cutting_10_18', d_cutting_10(:,9), 't_cutting_10_9');
% multiple target:
% calcItm(d_cutting_10, 'd_cutting_10', d_cutting_10, 'gen', {1 2 3 4 5 6 7 8 9});
% multiple target, generated, targets are not part of the feature matrix (pl. anton)
% tic; [a,b] = ffsa_rw(D_n_d, T, 'precalculated', true , 'features_mat', 'd_anton_20', 'target_mat', 'gen'); toc;
%
% anton
% [Target4] Started at 01-Nov-2016 10:56:24
% [Target4] Finished after 11997.5377 seconds. (=3.3326 hours)
% [Target5] Started at 01-Nov-2016 14:16:26
% [Target5] Finished after 12172.8146 seconds. (=3.3813 hours)
%

dispFlag = false;

if dispFlag, disp(['[calcItm] Started... ' datestr(datetime)]); end

if nargin == 5, featuremat_targetind = varargin{1}; end

fullPath_firstPart = getFullMatsPath();
fullPath_features = [fullPath_firstPart features_mat '.mat'];

if ~exist(fullPath_firstPart, 'dir'), mkdir(fullPath_firstPart); end

f_with_alt_dir = [fullPath_firstPart features_mat '_targets' filesep];
if ~exist(f_with_alt_dir, 'dir'), mkdir(f_with_alt_dir); end

ts = size(target,2);
if ischar(target_mat) && ~strcmp(target_mat, 'gen') % && ts == 1 % 1 target megadott névvel.
    fullPath_target = {[f_with_alt_dir target_mat '.mat']};
        
    if all([~strcmp(features_mat, 'none')
            ~strcmp(target_mat, 'none')
            exist(fullPath_features, 'file') == 2
            exist(fullPath_target{1}, 'file') == 2])
        if dispFlag, disp(['[calcItm] All exist. Finished... ' datestr(datetime)]); end
        return;
    end
elseif iscell(target_mat) || strcmp(target_mat, 'gen') % (ts > 1 && iscell(target_mat)) || (ts > 1 && strcmp(target_mat, 'gen')) % több target, cellábban nevekkel
    t_names = cell(ts,1);
    
    for idx = 1 : ts
        
        if strcmp(target_mat, 'gen') % generált nevekkel
            for jdx = 1 : size(featuremat_targetind,2)
                if ~isempty(featuremat_targetind{jdx}) % szerepel a featurematrixban a target
                    t_names{idx} = [f_with_alt_dir features_mat '_targetInd_' int2str(featuremat_targetind{idx}) '.mat'];
                else % nem szerepel, külön adtuk meg
                    t_names{idx} = [f_with_alt_dir features_mat '_genInd_' int2str(idx) '.mat'];
                end
            end
        else % ~gen, több target, cellábban nevekkel
            if  ischar(target_mat{idx}), tn = target_mat{idx}; else tn = int2str(target_mat{idx}); end
            t_names{idx} = [f_with_alt_dir features_mat '_targetInd_' tn '.mat'];
        end
        
    end
    
    fullPath_target = t_names;
else
    if ~strcmp(target_mat, 'none')
        error('Invalid target or target_mat arguments.'); end
end

if ~strcmp(features_mat, 'none') && exist(fullPath_features, 'file') == 2
    S = whos('-file', fullPath_features);
    l = false(1, 5);
    A = {'Ei', 'JEij', 'SUij', 'MIij', 'CORRij'};
    
    for k = 1 : length(S)
        l(cellfun(@(x) strcmp(x, S(k).name), A)) = true;
    end
    
    if ~all(l)
        error('Inconsistent features mat file');
    end
    
    load(fullPath_features, 'Ei', 'JEij', 'SUij', 'MIij', 'CORRij');
    
    if dispFlag, disp('[Feature matrix] Valid, loaded...'); end
else
    features_wrapper = WorkerObjWrapper(features);
    if dispFlag, disp(['[Feature matrix] Started at ' datestr(datetime)]); tic; end
    [Ei, JEij, SUij, MIij, CORRij] = calcItmF(features, features_wrapper);
    
    if dispFlag, tmp = toc; disp(['[Feature matrix] Finished after ' num2str(tmp) ' seconds. (=' num2str(tmp/3600) ' hours)']); end
    
    save(fullPath_features, 'Ei', 'JEij', 'SUij', 'MIij', 'CORRij');
end

for idx = 1 : size(fullPath_target, 1)
    
    fp_target = fullPath_target{idx};
    
    if ~strcmp(target_mat, 'none') && exist(fp_target, 'file') == 2
        S = whos('-file', fp_target);
        l = false(1, 7);
        A = {'Et', 'JEit', 'MIit', 'SUit', 'JEijt', 'JMIijt', 'SRijt', 'CORRit'};

        for k = 1 : length(S)
            l(cellfun(@(x) strcmp(x, S(k).name), A)) = true;
        end

        if ~all(l)
            error('Inconsistent target mat file');
        end
        
        if dispFlag, disp(['[Target' num2str(idx) '] Valid, checked...']); end
        % load(fullPath_target, 'Et', 'JEit', 'MIit', 'SUit', 'JEijt', 'JMIijt', 'SRijt', 'CORRit');
    else
        JEij_wrapper = WorkerObjWrapper(JEij);
        if ~exist('features_wrapper', 'var'), features_wrapper = WorkerObjWrapper(features); end
        if ~exist('Ei_wrapper', 'var'), Ei_wrapper = WorkerObjWrapper(Ei); end
        
        if dispFlag, disp(['[Target' num2str(idx) '] Started at ' datestr(datetime)]); tic; end; 
        [Et, JEit, MIit, SUit, JEijt, JMIijt, SRijt, CORRit] = calcItmT(features_wrapper, size(features,2), target(:,idx), Ei_wrapper, JEij_wrapper);
        
        if dispFlag, tmp = toc; disp(['[Target' num2str(idx) '] Finished after ' num2str(tmp) ' seconds. (=' num2str(tmp/3600) ' hours)']); end
    
        save(fp_target, 'Et', 'JEit', 'MIit', 'SUit', 'JEijt', 'JMIijt', 'SRijt', 'CORRit');
    end
end

if dispFlag, disp(['[calcItm] Finished... ' datestr(datetime)]); end

end