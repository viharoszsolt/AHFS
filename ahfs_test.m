%% running the algorithm

warning('off','all')
D = table2array(readtable('./demo_data/housing.csv', 'Delimiter', ';'));
I = D(:, 1:end-1);
T = D(:, end);

%not neccessarily needed, normalization is performed before ANN training
[I_n, I_np]= normalizer(I, [0.1 0.9]);
[T_n, T_np]= normalizer(T, [0.1 0.9]);

% in order for the information theoretic measures to be able to be computed
I_n_d = discretize(I_n, 20);
T_n_d = discretize(T_n, 20);

[fo, fd, E, allT_allSel, allE, asd] = ahfs(I_n, I_n_d, T_n, T_n_d, 'nfeatures', 13);

%% plotting the results

plot(E)
xticks(1:length(fo))
xticklabels(fo)
xlabel('Index of feature')
ylabel('Model error')
title('Time evolution of model error on the dataset Boston Housing')
saveas(gcf, './images/housing_error_curve.png')

