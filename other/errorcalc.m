function [error] = errorcalc(Output, Target)
%ERROREST Summary of this function goes here
%   Detailed explanation goes here

diff = Output - Target;
stdev = nanmean(bsxfun(@minus, Target, nanmean(Target)) .^ 2);

error = [nanmax(nanmean(diff .^ 2)) nanmax(nanmean(diff .^ 2) ./ stdev)...
         nanmean(nanmean(diff .^ 2)) nanmean(nanmean(diff .^ 2) ./ stdev)];
error = [error (error(1) / ((0.8 ^ 2) / 2)) ^ 0.5];

end

