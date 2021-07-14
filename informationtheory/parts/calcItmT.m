function [Et, JEit, MIit, SUit, JEijt, JMIijt, SRijt, CORRit] = calcItmT(features_wrapper, nfeatures, target, Ei_wrapper, JEij_wrapper)
% features_wrapper : WorkerObjWrapper instance of features matrix
% before using this function: features_wrapper = WorkerObjWrapper(features);
% nfeatures : number of features, size(features, 2)
%
% Ei_wrapper : WorkerObjWrapper instance of Entropy vector
% before using this function: Ei_wrapper = WorkerObjWrapper(Ei);
%
% JEij_wrapper : WorkerObjWrapper instance of Joint Entropy matrix
% before using this function: JEij_wrapper = WorkerObjWrapper(JEij);
%
% Et : 1xN double
% JEit : 1xN double
% MIit : 1xN double
% SUit : 1xN double
% JEijt : NxN double, upper triangular
% JMIijt : NxN double, upper triangular
% SRijt : NxN double, upper triangular
% CORRit : NxN double, upper triangular

%% CONSTS 
SKIP_JMI = true;

%% preallocation
p = gcp(); % check/create pool or empty (settings problem)
if isempty(p)
    disp('Create a parallel pool manually first.');
end

uti = nchoosek(1:nfeatures, 2); % upper triangular indices
uti_wrapper = WorkerObjWrapper(@nchoosek, {1:nfeatures, 2});
% uti_wrapper = WorkerObjWrapper(uti);

%% calculate Et
Et = Entropy(target);
Et_wrapper = WorkerObjWrapper(Et);
target_wrapper = WorkerObjWrapper(target);

%% calculate JEit, MIit, SUit, CORRit
[JEit, MIit, SUit, CORRit] = deal(zeros(1, nfeatures));

parfor idx = 1 : nfeatures
    wv = features_wrapper.Value;
    w2v = target_wrapper.Value;
    w3v = Ei_wrapper.Value;
    w4v = Et_wrapper.Value;
    
    % Ei + Et 
    sumEit = w3v(idx) + w4v;
    
    je = JointEntropy([wv(:, idx) w2v]);
    JEit(idx) = je;
    MIit(idx) = sumEit - je;
    SUit(idx) = 2 * ((sumEit - je) / sumEit);
    c = corrcoef([wv(:, idx), w2v]);
    CORRit(idx) = c(2,1);
end


%% calculate JEijt, JMIijt, SRijt

[JEijt, JMIijt, SRijt] = deal(-ones(nfeatures));

if ~SKIP_JMI 

    [tempJEijt, tempJMIijt, tempSRijt] = deal(zeros(size(uti,1), 1));

    parfor idx = 1 : size(uti, 1)
        wv = features_wrapper.Value;
        w2v = uti_wrapper.Value;
        w3v = target_wrapper.Value;
        w4v = Et_wrapper.Value;
        w5v = JEij_wrapper.Value;

        % JEijt
        je3 = JointEntropy([wv(:, w2v(idx, 1)), wv(:, w2v(idx, 2)), w3v]);
        tempJEijt(idx) = je3; 

        % JMIijt
        jmi = w4v - (je3 - w5v(w2v(idx, 1), w2v(idx, 2)));
        tempJMIijt(idx) = jmi;

        % SRijt 
        tempSRijt(idx) = jmi / je3;
    end

    for ind = 1 : size(uti, 1)
        idx = uti(ind,1); jdx = uti(ind,2);
        JEijt(idx, jdx) = tempJEijt(ind);
        JMIijt(idx, jdx) = tempJMIijt(ind);
        SRijt(idx, jdx) = tempSRijt(ind);
    end

end