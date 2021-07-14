function [Ei, JEij, SUij, MIij, CORRij] = calcItmF(features, features_wrapper)
% features_wrapper : WorkerObjWrapper instance of features matrix
% before using this function: features_wrapper = WorkerObjWrapper(features);
%
% nfeatures : number of features, size(features, 2)
%
% Ei : 1xN double
% JEij : NxN double, upper triangular
% SUij : NxN double, upper triangular
% MIij : NxN double, upper triangular
% CORRij : NxN double, upper triangular

%% preallocation
p = gcp(); % check/create pool or empty (settings problem)
if isempty(p)
    disp('Create a parallel pool manually first.');
end

nfeatures = size(features,2);
uti = nchoosek(1:nfeatures, 2); % upper triangular indices
uti_wrapper = WorkerObjWrapper(@nchoosek, {1:nfeatures, 2});
% uti_wrapper = WorkerObjWrapper(uti);

%% calculate Ei
Ei = -ones(1, nfeatures);
parfor idx = 1 : nfeatures
    wv = features_wrapper.Value;
    Ei(idx) = Entropy(wv(:,idx));
end
Ei_wrapper = WorkerObjWrapper(Ei);

%% calculate JEij, MIij, SUij, CORRij
[tempJEij, tempSUij, tempMIij, tempCORRij] = deal(zeros(size(uti,1), 1));

parfor idx = 1 : size(uti, 1)
    wv = features_wrapper.Value;
    w2v = uti_wrapper.Value;
    w3v = Ei_wrapper.Value;
    
    % Ei + Ej
    sumEij = w3v(w2v(idx, 1))+w3v(w2v(idx, 2));
    
    % JEij
    je = JointEntropy([wv(:, w2v(idx, 1)), wv(:, w2v(idx, 2))]);
    tempJEij(idx) = je; 
    
    % MIij
    tempMIij(idx) = sumEij - je;
    
    % SUij 
    tempSUij(idx) = 2 * ((sumEij - je) / sumEij);
    
    % c = corrcoef([wv(:, w2v(idx, 1)), wv(:, w2v(idx, 2))]);
    % tempCORRij(idx) = c(2, 1);
end

CORRij = corrcoef(features);

[JEij, SUij, MIij] = deal(-ones(nfeatures));
for ind = 1 : size(uti, 1)
    idx = uti(ind,1); jdx = uti(ind,2);
    JEij(idx, jdx)   = tempJEij(ind);
    MIij(idx, jdx)   = tempMIij(ind);
    SUij(idx, jdx)   = tempSUij(ind);
    % CORRij(idx, jdx) = tempCORRij(ind);
end

end