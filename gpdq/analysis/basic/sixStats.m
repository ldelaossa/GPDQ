%% sixStats
% Obtains six statistical values of interest from a vector of numbers.
% Discards NaN elements, and reports the number of NaN.
%
% Usage
% -----
%
%       stats = sixStats(vector)
%
% Parameters
% ----------
%
%   vector: Vector of numbers. NaN values are allowed.
%
% Returns
% -------
%
%   stats: 6-element vector containing the results:
%
%       # Maximum value
%       # Minimum value
%       # Mean value
%       # Standard deviation
%       # Sum of all non-null values
%       # Number of elements considered (only those which are not NaN).
%
% Errors
% ------
%
% Reports error if the vector is empty.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function stats = sixStats(vector)

stats = zeros(6,1);

% If the vector is empty, reports the error.
if isempty(vector)
    msg = 'The vector is empty';
    Status.repError(msg, false, dbstack());
    stats = Status.ERROR;
    return;
end

% Deletes NaN elements from the vector.
cleanVector = vector(~isnan(vector));

% If there is more than one element, calculates the statistics.
if numel(cleanVector)>0
    stats(1) = max(cleanVector);
    stats(2) = min(cleanVector);
    stats(3) = mean(cleanVector);
    stats(4) = std(cleanVector);
    stats(5) = sum(cleanVector);
    stats(6) = numel(cleanVector);
% Otherwise all returning values are set to NaN
else
    stats(1) = NaN;
    stats(2) = NaN;
    stats(3) = NaN;
    stats(4) = NaN;
    stats(5) = NaN;
    stats(6) = NaN;
end

end

