function [fullPath_features, fullPath_target, cleanUpObj] = tempItm(features, target, it_struct, autocleanup)

% meg�rni, hogy skippeljen ha l�tezik temp 
%
% autocleanup - boolean
% [pathstr,name,ext] = fileparts(mfilename('fullpath'));


dispFlag = false;

if dispFlag, disp(['[tempItm] Started... ' datestr(datetime)]); end

fullPath_firstPart = [tempdir 'MATLAB' filesep 'temp_itm'];
fullPath_features = [fullPath_firstPart filesep 'temp_feature_matrices.mat'];
f_with_alt_dir = [fullPath_firstPart filesep 'temp_targets' filesep];

if ~exist(fullPath_firstPart, 'dir'), mkdir(fullPath_firstPart); end
if ~exist(f_with_alt_dir, 'dir'), mkdir(f_with_alt_dir); end

ts = size(target,2);
nfeatures = size(features,2);

fullPath_target = cell(ts,1);

for idx = 1 : ts, fullPath_target{idx} = [f_with_alt_dir 'temp_targets_genInd_' int2str(idx) '.mat']; end

if ~autocleanup && exist(fullPath_features, 'file')==2 && sum(cellfun(@(x) exist(x, 'file'), fullPath_target)==2)==ts
    cleanUpObj = [];
    if dispFlag, disp(['[tempItm] Found... ' datestr(datetime)]); end
    
    %return; !!!!!!!!!returnt kivettem
end
 %!!!!!!!!!!!!!!athelyeztem a file vegerol az oncleanup cuccot, ami
 % eredetileg magaban allt if nelkul
 % ez csak a legelso tempitm hivasnal ertekelodik ki
first_run=~(~autocleanup && exist(fullPath_features, 'file')==2 && sum(cellfun(@(x) exist(x, 'file'), fullPath_target)==2)==ts);
if first_run
    cleanUpObj = onCleanup(@deleteTemp);
    
end


% ezek segítségével fogom ellenőrizni, hogy megvannak-e a szükséges mátrixok
matobj_feat = matfile(fullPath_features);

%ki vannak már számolva a feature spec. mx-ok?

CORRij_ok = logical(sum(cellfun(@(x) isequal(x, 'CORRij'), who(matobj_feat))));
MIij_ok = logical(sum(cellfun(@(x) isequal(x, 'MIij'), who(matobj_feat))));
SUij_ok = logical(sum(cellfun(@(x) isequal(x, 'SUij'), who(matobj_feat))));
JEij_ok = logical(sum(cellfun(@(x) isequal(x, 'JEij'), who(matobj_feat))));


fp_target = fullPath_target{1};
matobj_targ = matfile(fp_target);
%megvannak-e a target spec. mátrixok
    
CORRit_ok = logical(sum(cellfun(@(x) isequal(x, 'CORRit'), who(matobj_targ))));
MIit_ok = logical(sum(cellfun(@(x) isequal(x, 'MIit'), who(matobj_targ))));
SUit_ok = logical(sum(cellfun(@(x) isequal(x, 'SUit'), who(matobj_targ))));
JEit_ok = logical(sum(cellfun(@(x) isequal(x, 'JEit'), who(matobj_targ))));



%% preallocation
p = gcp(); % check/create pool or empty (settings problem)
if isempty(p)
    disp('Create a parallel pool manually first.');
end

%sum(ismember(fieldnames(s), 'MIit'))>0

uti_is_needed = false;
if ~it_struct.CORRij 
    uti_is_needed = sum(cell2mat(struct2cell(it_struct))) > 0;
end


uti = nchoosek(1:nfeatures, 2); % upper triangular indices
kell_vlmi_feat = ((~MIij_ok && it_struct.MIij) || (~SUij_ok && it_struct.SUij));
if uti_is_needed && kell_vlmi_feat
uti_wrapper = WorkerObjWrapper(@nchoosek, {1:nfeatures, 2});
% uti_wrapper = WorkerObjWrapper(uti);
end

%% feature temp mat file

% Ei : 1xN double
% JEij : NxN double, upper triangular
% SUij : NxN double, upper triangular
% MIij : NxN double, upper triangular
% CORRij : NxN double, upper triangular

% calculate Ei
% entrópia mx-nak helyet foglalni csak elsőre
if first_run
    Ei = -ones(1, nfeatures);
end
if kell_vlmi_feat || (~MIit_ok && it_struct.MIit) || (~CORRit_ok && it_struct.CORRit)  %ffsa miatt raktam be a vagy jobb oldalát, annál nincs párban a feat spec és a targ spec
    features_wrapper = WorkerObjWrapper(features);
end
% ez az entrópia (feature) konkrét kiszámolása, ezt csak egyszer
if first_run
    parfor idx = 1 : nfeatures
        wv = features_wrapper.Value;
        Ei(idx) = Entropy(wv(:,idx));
        if idx==1, disp('computing feature entropy'); end
    end
    save(fullPath_features, 'Ei');
    Ei_wrapper = WorkerObjWrapper(Ei);
elseif kell_vlmi_feat || (~MIit_ok && it_struct.MIit) %akkor töltöm vissza, ha szükség van rá, tehát szükség van az Ei_wrapperra
    load(fullPath_features, 'Ei');
    Ei_wrapper = WorkerObjWrapper(Ei);
end


%feature spec matrixok inic. csak az első alkalommal, mikor indokolt

if ~JEij_ok && (it_struct.MIij || it_struct.SUij)
    JEij = nan(nfeatures, nfeatures);
end
if ~MIij_ok && it_struct.MIij
    MIij = nan(nfeatures, nfeatures);
end
if ~SUij_ok && it_struct.SUij
    SUij = nan(nfeatures, nfeatures);
end
if ~CORRij_ok && it_struct.CORRij
    CORRij = nan(nfeatures, nfeatures);
end

%% calculate JEij, MIij, SUij, CORRij

if uti_is_needed && kell_vlmi_feat
    
    if ~JEij_ok && (it_struct.MIij || it_struct.SUij)
        tempJEij = zeros(size(uti,1), 1);
    end
    if ~MIij_ok && it_struct.MIij
        tempMIij = zeros(size(uti,1), 1);
    end
    if ~SUij_ok && it_struct.SUij
        tempSUij = zeros(size(uti,1), 1);
    end
    
    
    %SUij, MIij kiszámolás
    parfor idx = 1 : size(uti, 1)
        if idx==1
            disp('computing JEij')
        end
        wv = features_wrapper.Value;
        w2v = uti_wrapper.Value;
        w3v = Ei_wrapper.Value;

        % Ei + Ej
        sumEij = w3v(w2v(idx, 1))+w3v(w2v(idx, 2));

        % JEij
        je = JointEntropy([wv(:, w2v(idx, 1)), wv(:, w2v(idx, 2))]);
        tempJEij(idx) = je; 
        
        if it_struct.MIij && ~MIij_ok
            % MIij
            if idx==1
                disp('computing MIij')
            end
            tempMIij(idx) = sumEij - je;
        end
        
       
        if it_struct.SUij && ~SUij_ok
            % SUij 
            if idx==1
                disp('computing SUij')
            end
            tempSUij(idx) = 2 * ((sumEij - je) / sumEij);
        end
        
        %         if it_struct.CORRij
        %             c = corrcoef([wv(:, w2v(idx, 1)), wv(:, w2v(idx, 2))]);
        %             tempCORRij(idx) = c(2, 1);
        %         end
    end
    
    
    %SUij, JEij, MIij mx-ba berakás
    for ind = 1 : size(uti, 1)
        idx = uti(ind,1); jdx = uti(ind,2);
        if ~JEij_ok && (it_struct.MIij || it_struct.SUij)
            JEij(idx, jdx)   = tempJEij(ind);
        end
        if ~MIij_ok && it_struct.MIij
            MIij(idx, jdx)   = tempMIij(ind);
        end
        if ~SUij_ok && it_struct.SUij
            SUij(idx, jdx)   = tempSUij(ind);
        end
        %         CORRij(idx, jdx) = tempCORRij(ind);
    end
    %mx-ok mentése, ha kell
    if ~JEij_ok && (it_struct.MIij || it_struct.SUij)
        disp('saving JEij')
        save(fullPath_features, 'JEij', '-append');
    end
    if ~MIij_ok && it_struct.MIij
        disp('saving MIij')
        save(fullPath_features, 'MIij', '-append');
    end
    if ~SUij_ok && it_struct.SUij
        disp('saving SUij')
        
        save(fullPath_features, 'SUij', '-append');
    end
end

if it_struct.CORRij && ~CORRij_ok      % faster.... really. faster. 
    disp('computing and saving CORRij')
    CORRij = corrcoef(features);
    save(fullPath_features, 'CORRij', '-append');
end


% target temp mat files

for idx = 1 : size(fullPath_target, 1)
    
    
    % Et : 1xN double
    % JEit : 1xN double
    % MIit : 1xN double
    % SUit : 1xN double
    % CORRit : 1xN double, upper triangular
    % JEijt : NxN double, upper triangular
    % JMIijt : NxN double, upper triangular
    % SRijt : NxN double, upper triangular
    
    % calculate Et
    % Et kiszámolása csak az első futásnál, utána csak visszatöltöm, ha még
    % kell vlmit számolni
    
    
    
    
    kell_vlmi_targ_de_nem_corr = ((~MIit_ok && it_struct.MIit) || (~SUit_ok && it_struct.SUit));
    kell_vlmi_targ = ((~MIit_ok && it_struct.MIit) || (~SUit_ok && it_struct.SUit) ||...
        (~CORRit_ok && it_struct.CORRit));
    if first_run
        Et = Entropy(target(:, idx));
        save(fp_target, 'Et');
        Et_wrapper = WorkerObjWrapper(Et);
    elseif kell_vlmi_targ_de_nem_corr
        load(fp_target, 'Et');
        Et_wrapper = WorkerObjWrapper(Et);
    end
    if kell_vlmi_targ_de_nem_corr || (~CORRit_ok && it_struct.CORRit)  %corrit-hez is kell target wrapper
        target_wrapper = WorkerObjWrapper(target(:, idx));
    end
    %JEij_wrapper = WorkerObjWrapper(JEij);  ezt kivettem, ez csak az
    %irreleváns mennyiségekhez kellene
    
    % calculate JEit, MIit, SUit, CORRit
    
    if ~JEit_ok && (it_struct.MIit || it_struct.SUit)
        JEit = zeros(1, nfeatures);
    end
    if ~MIit_ok && it_struct.MIit
        MIit = zeros(1, nfeatures);
    end
    if ~SUit_ok && it_struct.SUit
        SUit = zeros(1, nfeatures);
    end
    if ~CORRit_ok && it_struct.CORRit
        CORRit = zeros(1, nfeatures);
    end
   
    if kell_vlmi_targ
        if kell_vlmi_targ_de_nem_corr
             parfor jdx = 1 : nfeatures
                    
                    wv = features_wrapper.Value;
                    w2v = target_wrapper.Value;
                    w3v = Ei_wrapper.Value;
                    w4v = Et_wrapper.Value;

                    % Ei + Et 
                    sumEit = w3v(jdx) + w4v;
                    if jdx==1
                            disp('computing JEit')
                    end
                    je = JointEntropy([wv(:, jdx) w2v]);
                    JEit(jdx) = je;
                    if ~MIit_ok && it_struct.MIit
                        if jdx==1
                            disp('computing MIit')
                        end
                        MIit(jdx) = sumEit - je;
                    end
                    if ~SUit_ok && it_struct.SUit
                        if jdx==1
                            disp('computing SUit')
                        end
                        SUit(jdx) = 2 * ((sumEit - je) / sumEit);
                    end
             end
        end
        if ~CORRit_ok && it_struct.CORRit
            disp('computing CORRit')
            parfor kdx = 1 : nfeatures
                wv = features_wrapper.Value;
                w2v = target_wrapper.Value;
                c = corrcoef([wv(:, kdx), w2v]);
                CORRit(kdx) = c(2,1);
            end
        end
    end
    %mentése a target spec. mx-oknak, ha kell
    if ~JEit_ok && (it_struct.MIit || it_struct.SUit)
        disp('saving JEit')
        save(fp_target, 'JEit', '-append');
    end
    if ~MIit_ok && it_struct.MIit
        disp('saving MIit')
        save(fp_target, 'MIit', '-append');
    end
    if ~SUit_ok && it_struct.SUit
        disp('saving SUit')
        
        save(fp_target, 'SUit', '-append');
    end
    
    if ~CORRit_ok && it_struct.CORRit
        disp('saving CORRit')
        save(fp_target, 'CORRit', '-append');
    end
    
end
    
if dispFlag, disp(['[tempItm] Finished... ' datestr(datetime)]); end




end