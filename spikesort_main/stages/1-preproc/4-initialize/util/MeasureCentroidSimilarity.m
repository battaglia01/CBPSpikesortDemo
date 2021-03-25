% This function takes the cluster centroids and measures how similar they
% are, using the similarity method set by the user in
% params.clustering.similarity_method ("shiftcorr" is the default).
% It returns the similarity matrix and the method used.
function centroid_scores =...
    MeasureCentroidSimilarity(all_centroids, nchan, similarity_method)
    
% A note -
% We are going to compare *all* waveform centroids - not just those being
% chosen as "active plot" waveforms. This matrix has each *flattened*
% centroid as the column vectors, so the number of columns is the
% number of *all* cells.
% We also want to dynamically recompute the number of estimated cells
% on-the-fly, as the user may have changed the
% params.clustering.num_waveforms param and simply just have refreshed
% the plot without recomputing...
num_all_est_cells = size(all_centroids, 2);

% Now, we are going to compare each centroid with all time-shifts of
% the other centroids. These are multi-channel centroids, though! The
% way we do this is to first un-flatten the centroid, zero pad each
% channel with a bunch of zeros, and then re-flatten. Then, if we
% simply x-corr the flattened vectors (or even circularly x-corr), we
% should get a decent metric for the xcorr'd distance between the
% vectors.
% The params.clustering.similarity_method parameter determines if we do
% time-shifting, but we just compute these anyway - maybe unnecessary,
% but it's alright - we can optimize if need be.
% We'll store this in the "padded_centroids" matrix.
% The padding amount is the length of each centroid per channel, which is
% the length of the flattened centroid divided by the number of channels.
waveform_len = size(all_centroids, 1)/nchan;
centroid_len = nchan * waveform_len;
padded_centroid_len = 2 * centroid_len;
padded_centroids = [];
for n=1:num_all_est_cells
    tmp_centroid = all_centroids(:, n);
    tmp_centroid = reshape(tmp_centroid, [], nchan);
    tmp_centroid = [tmp_centroid; zeros(waveform_len, nchan)];
    padded_centroids(:, n) = tmp_centroid(:);
end

% Now we create the similarity/difference matrix
% (depending on how our param is set - if it's "shiftcorr", then higher
% scores indicate greater similarity, whereas if it's "shiftdist", then
% lower scores indicate greater similarity. We store the results in
% this matrix:
centroid_scores = zeros(num_all_est_cells);

% Now we branch on the similarity method and calculate the similarity
if isequal(similarity_method, "shiftcorr")
    % this method takes the max value of the xcorr between them, and uses
    % it to compute a "shift-invariant cosine similarity." 
    centroid_scores = zeros(num_all_est_cells);
    for r=1:num_all_est_cells
        for c=r:num_all_est_cells
            if r == c
                centroid_scores(r, r) = rms(all_centroids(:, r));
            else
                centroid_scores(r, c) = ...
                    max(xcorr(padded_centroids(:, r), ...
                              padded_centroids(:, c))) ...
                      / (norm(all_centroids(:, r)) * ...
                         norm(all_centroids(:, c)));
                centroid_scores(c, r) = centroid_scores(r, c);
            end
        end
    end
elseif isequal(similarity_method, "shiftdist")
    % This method gets the shortest distance between all possible shifts of
    % waveforms with one another.
    %
    % There's a nice easy way to compute this. Given two vectors a, b, we
    % have ||a - b||^2 = ||a||^2 + ||b||^2 - 2<a,b>. Now, if we're looking
    % for the time-shift that yields the shortest distance between a and b,
    % the only term that changes in the above equation is that <a,b> - the
    % ||a||^2 and ||b||^2 are shift-invariant. The distance decreases as
    % <a,b> increases - which means we need to look for the time-shift that
    % maximizes <a,b>, which thus means we are looking for the time-index
    % for which xcorr(a,b) is maximized.
    %
    % unlike the above, we'll first get the squared-L2 norm of everything
    centroid_scores = zeros(num_all_est_cells);
    for r=1:num_all_est_cells
        for c=r:num_all_est_cells
            if r == c
                % The distance from every waveform to itself is 0. So
                % instead of having the diagonal be all zeros, for the sake
                % of putting useful information in there, we'll put the RMS
                % of each waveform
                centroid_scores(r, r) = rms(all_centroids(:, r));
            else
                % first get the squared L2 norm of the difference between
                % the vectors, then convert to RMS
                squared_norm = norm(padded_centroids(:, r))^2 + ...
                               norm(padded_centroids(:, c))^2 - ...
                               2*max(xcorr(padded_centroids(:, r), padded_centroids(:, c)));
                rms_diff = sqrt(1/(centroid_len) * squared_norm);
                centroid_scores(r, c) = rms_diff;
                centroid_scores(c, r) = rms_diff;
            end
        end
    end
elseif isequal(similarity_method, "magspectrumcorr")
    % This method gets the cosine similarity between magnitude spectra,
    % which is already shift-invariant in the time-domain.
    % 
    % This is pretty experimental, but the basic idea is: suppose you
    % multiply the true spectra together, aka convolve the waveforms
    % together in the time domain. If you then take the norm of the result,
    % this will be less if the two waveforms share less frequency
    % components in common. You get the same norm regardless of if you
    % multiply the true spectra or just the magnitude spectra, since the
    % phase information is discarded when taking the norm.
    %
    % What we're doing is *almost* the same as the above - it would be
    % exactly the same if we took the dot product of the *squares* of the
    % magnitude spectra, rather than the magnitude spectra directly. The
    % way we're doing it may scale nicer for waveforms with low
    % amplitudes. We also divide by the norms of the waveforms to get a
    % "cosine similarity" measure.

    % We take the FFT of the *padded* centroids to prevent time-aliasing.
    % Note that the MATLAB `fft` function takes a 1D fft separately of each
    % column.
    mag_centroids = abs(fft(padded_centroids)) / sqrt(padded_centroid_len);
    
    % Now, by multiplying this matrix with its transpose, we get the
    % dot products, with the diagonal being the norm-squared
    dot_products = mag_centroids'*mag_centroids;

    % And lastly, we divide each entry by the product of the norms of both
    % corresponding waveforms. To do this, we take the diagonal of the
    % above matrix, take the pointwise square root, and take the outer
    % product:
    norms = sqrt(diag(dot_products));
    norm_products = norms * norms';
    
    % Now we do a pointwise division and we have our cosine similarity:
    centroid_scores = dot_products ./ norm_products;
    
    % Lastly, we want to replace the diagonal with the RMS of each
    % waveform. The following matrix expression does that:
    rms_norms = norms * 1./sqrt(centroid_len);
    centroid_scores = centroid_scores - diag(diag(centroid_scores));
    centroid_scores = centroid_scores + diag(rms_norms);
elseif isequal(similarity_method, "magspectrumshift")
    % This method gets the distance between magnitude spectra,
    % which is already shift-invariant in the time-domain.
    % 
    % This is pretty experimental, and is a variation of the above. The
    % basic idea is, suppose we got the L2 norm of the difference between
    % the *square* of the magnitude spectra. This is also the L2 norm of
    % the difference between the autocorrelation functions. We would have
    %   ||a.^2 - b.^2||
    %   = <a.^2, a.^2>  - 2<a.^2, b.^2> + <b.^2, b.^2>
    %   = ||a||^4 + ||b||^4 - 2<a.^2, b.^2>
    % 
    % What we're doing is basically the same as this, except we just do it
    % with the regular magnitude spectrum rather than the squared magnitude
    % spectrum, which should scale better for small waveforms,
    % so that we get:
    %   = ||a||^2 + ||b||^2 - 2<|a|,|b|>
    % 
    % Note that last term is the thing computed in the "magspectrumcorr"
    % method, although without normalizing by the product of norms.
    % So, this thing is closely related.

    % We take the FFT of the *padded* centroids to prevent time-aliasing.
    % Note that the MATLAB `fft` function takes a 1D fft separately of each
    % column.
    mag_centroids = abs(fft(padded_centroids)) / sqrt(padded_centroid_len);
    
    % Now, by multiplying this matrix with its transpose, we get the
    % dot products, with the diagonal being the norm-squared
    dot_products = mag_centroids'*mag_centroids;

    % Now the diagonal is our norm squared, so we create two rank-one
    % matrices - one in which all the rows are just the same vector of
    % squared norms, and one in which the cols are just the same vector of
    % squared norms
    squared_norms = diag(dot_products);
    rows_squared_norms = repmat(squared_norms', ...
                                size(dot_products, 1), 1);
    cols_squared_norms = repmat(squared_norms, ...
                                1, size(dot_products, 2));

    % We use this to get our squared distances, and then our RMS distances
    % by dividing by the number of elements in the waveforms and taking the
    % square root
    squared_distances = rows_squared_norms + cols_squared_norms ...
                        - 2*dot_products;
    centroid_scores = sqrt(1./centroid_len.* (squared_distances));
    
    % Now, the only thing left is that doing this has made our diagonal all
    % zeros. Since that's not helpful information, we'll instead change the
    % diagonal to the RMS of each centroid:
    
    centroid_scores = centroid_scores + ...
        diag(sqrt(1./centroid_len .* squared_norms));
elseif isequal(similarity_method, "simple")
    % This method simply takes the distance between two waveforms
    % without any time-shifting compensation. This method may not
    % realize when two waveforms are time-shifted versions of one
    % another.


    % There's a nice easy way to compute this. Given two vectors a, b, we
    % have ||a - b||^2 = ||a||^2 + ||b||^2 - 2<a,b>. So, we can get our
    % answer with a little matrix algebra:
    dot_products = all_centroids' * all_centroids;
    
    % Now the diagonal is our norm squared, so we create two rank-one
    % matrices - one in which all the rows are just the same vector of
    % squared norms, and one in which the cols are just the same vector of
    % squared norms
    squared_norms = diag(dot_products);
    rows_squared_norms = repmat(squared_norms', ...
                                size(dot_products, 1), 1);
    cols_squared_norms = repmat(squared_norms, ...
                                1, size(dot_products, 2));

    % We use this to get our squared distances, and then our RMS distances
    % by dividing by the number of elements in the waveforms and taking the
    % square root
    squared_distances = rows_squared_norms + cols_squared_norms ...
                        - 2*dot_products;
    centroid_scores = sqrt(1./centroid_len.* (squared_distances));
    
    % Now, the only thing left is that doing this has made our diagonal all
    % zeros. Since that's not helpful information, we'll instead change the
    % diagonal to the RMS of each centroid:
    
    centroid_scores = centroid_scores + ...
        diag(sqrt(1./centroid_len .* squared_norms));
else
    error("Invalid value in params.clustering.similarity_method!");
end
