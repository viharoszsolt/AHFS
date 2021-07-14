function PE = percentage_error(e)
% e : error -> targetSize X numOfTrain (MSE)
% PE : percentage error -> targetSize X numOfTrain

PE = (e ./ ((0.8 .^ 2) / 2)) .^ 0.5;

end