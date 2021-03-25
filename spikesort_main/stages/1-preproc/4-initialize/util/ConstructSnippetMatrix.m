% Construct a matrix where each column is a snippet of the trace centered
% about peak (vectorized across channels). Peak is computed by upsampling
% the trace, computing the root-mean-squared value across channels, and
% then smoothing. Then the trace is downsampled back to the original
% resolution.
%
% data : channel x time matrix
% peak_idx : time indices of candidate spikes.
% pars : parameters

function X = ConstructSnippetMatrix(data, peak_idx, pars)
    wlen = floor(pars.window_len / 2);
    wlen_fine = floor(pars.window_len * pars.upsample_fac / 2);
    if (pars.downsample_after_align)
        X = zeros(pars.window_len * size(data, 1), length(peak_idx));
    else
        X = zeros(pars.window_len * pars.upsample_fac * size(data, 1), ...
                  length(peak_idx));
    end

    % time axis
    xax = (1 : pars.window_len);
    % finely sample time axis
    fine_xax = (1 : 1 / pars.upsample_fac : pars.window_len);

    % Populate the matrix X one column at a time.
    for i = 1 : length(peak_idx)
        % added check to make sure we don't overflow
        if peak_idx(i) + wlen > length(data) || ...
           peak_idx(i) - wlen < 1;
           continue;
        end
        % Extract snippet from the data
        x = data(:, peak_idx(i) + (-wlen : wlen));
        if pars.upsample_fac <= 1
            X(:, i) = reshape(x', [], 1);
            continue;
        end

        % Upsample using cubic interpolation
        x_fine = zeros(size(x, 1), length(fine_xax));
        for j = 1 : size(x, 1)
            x_fine(j, :) = interp1(xax, x(j, :), fine_xax, 'pchip');
        end
        % Smooth the averaged mixdown of x_fine.
        x_fine_averaged = [];
        switch(pars.averaging_mode)
            case 'L1'
                x_fine_averaged = sum(abs(x_fine), 1);
            case 'L2'
                x_fine_averaged = sqrt(sum(x_fine .^ 2, 1));    %%@ RMS vs L2?
            case 'Linf'
                x_fine_averaged = max(abs(x_fine), [], 1);
            case 'max'
                x_fine_averaged = sum(x_fine, 1);
                %%@ add this for the median-based methods
                x_fine_averaged(x_fine_averaged < 0) = 0;
            case 'min'
                x_fine_averaged = sum(-x_fine, 1);
                %%@ add this for the median-based methods
                x_fine_averaged(x_fine_averaged < 0) = 0;
            otherwise
                error("Invalid averaging mode!")
        end
        x_fine_averaged = smooth(x_fine_averaged, pars.smooth_len);

        % Align to max value of the smoothed, upsampled one-channel average.
        % We can also align to the centroid or median, depending on what
        % `alignment_mode` is set to.
        if isequal(pars.alignment_mode, 'peak')
            [~, max_idx] = max(x_fine_averaged);
        elseif isequal(pars.alignment_mode, 'centroid')
            moment_0 = sum(x_fine_averaged);
            moment_1 = sum(x_fine_averaged .* ...
                           (1:length(x_fine_averaged))');
            max_idx = round(moment_1/moment_0);
            [~, tmp] = max(x_fine_averaged);
        elseif isequal(pars.alignment_mode, 'median')
            moment_0 = sum(x_fine_averaged);
            tmp = x_fine_averaged / moment_0;
            cdf_tmp = cumsum(tmp);
            
            max_idx = min(find(cdf_tmp >= 0.5));
        elseif isequal(pars.alignment_mode, 'none')
            max_idx = round(length(x_fine_averaged)/2);
        end
        
        % clear x_fine_averaged;
        % DOWNSAMPLE BACK TO ORIGINAL RESOLUTION
        if (pars.downsample_after_align)
            new_xax = (max_idx - pars.upsample_fac * wlen) : ...
                pars.upsample_fac : ...
                (max_idx + pars.upsample_fac * wlen);
        else
            % DO NOT DOWNSAMPLE - leave in fine resolution
            new_xax = max_idx + (-wlen_fine : wlen_fine);
        end
        sub_idx = new_xax > 0 & new_xax <= size(x_fine, 2);
        lhs_pad = sum(new_xax < 1);
        rhs_pad = sum(new_xax > size(x_fine, 2));
        tmp = x_fine(:, new_xax(sub_idx));
        tmp = padarray(tmp, [0 lhs_pad], 0, 'pre');
        tmp = padarray(tmp, [0 rhs_pad], 0, 'post');

        % Populate matrix (vectorize across channels).
        X(:, i) = reshape(tmp', [], 1);
    end
end
