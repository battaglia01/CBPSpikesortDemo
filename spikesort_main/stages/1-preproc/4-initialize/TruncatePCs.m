% Get principal components accounting for desired percent variance
% Return the PCs as well as the projections of the data on to these PCs
% (PX)
function [PCs, XProj] = TruncatePCs(X, percent_variance)
fprintf('Doing PCA...');
% Get PCs
if exist('pca', 'file')
    %[PCs, Xproj, latent] = pca(X');
    [PCs, Xproj, latent] = pca(X', 'Centered', false);
else
    [PCs, Xproj, latent] = princomp(X');
    origin = mean(X');
    PCs = PCs + repmat(origin', 1, size(PCs,2));
    Xproj = Xproj + repmat(origin, size(Xproj,1), 1);
end


[latent sorted_idx] = sort(latent, 'descend');
PCs = PCs(:,sorted_idx);
Xproj = Xproj(:, sorted_idx);

% Figure out how many PCs we need to account for
% the desired percent of total variance
cutoff = find(cumsum(latent) ./ sum(latent) * 100 > percent_variance, 1);
npcs = max(2, cutoff);
fprintf('%d/%d PCs account for %.2f percent variance\n', ...
        npcs, length(latent), percent_variance);
% Project onto leading npcs PCs
PC = PCs(:, 1 : npcs);
% Project on to PCs
XProj = Xproj(:, 1 : npcs);
