
function [pCenters, pRadii] = detectParticles10Nm(image, scale, margin, sensitivity, threshold)
global model10

% First of all, detects the candidates.
[cCenters, cRadii, cMetrics] = detectCandidates(image, scale, 5, margin, sensitivity, 0.5, 500);

% Extracts particles
[cValid, cFeatures] = getCandidateFeatures10Nm(image, scale, cCenters, cRadii, cMetrics);


% Discards non valid points (those whose features have not been obtained).
cFeatures = cFeatures(cValid,:);
cCenters = cCenters(cValid,:);
cRadii = cRadii(cValid);

% Classifies the candidate circles
% Applies PCA to 400 pixels and adds the 4 metrics.
X = (cFeatures(:,1:end-4)-model10.pca.mu)*model10.pca.coeff(:,1:model10.pca.n_components);
X = [X, cFeatures(:,end-3:end)];       
% Classifies    
y = model10.classifier(X')>threshold;

% Returns the centers
pCenters = cCenters(y,:);
pRadii = cRadii(y,:);


% Debug
debug = true;

if debug % Shows the original image and the detected candidates.
    imshow(image);
    markPoints(pCenters/scale, 5/scale, '-', 1, 'red', false);
end

end

