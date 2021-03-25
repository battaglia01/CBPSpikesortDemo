% This takes the ground truth waveforms and filters and whitens them to
% match the filtered/whitened input.
%
% We expect the input to be:
%    - a cell array of waveforms
%    - CBPdata.filtering.coeffs
%    - CBPdata.whitening.old_acfs (these are used to whiten temporally)
%    - CBPdata.whitening.old_cov (used for whitening spatially)
%    - params.whitening.reg_const (used internally for both whitenings)
% function out = RefilterAndWhitenWaveforms(in)
function out = RefilterAndWhitenWaveforms(in, coeffs, old_acfs, old_cov, reg_const)
    % number of channels is number of columns in first (and all) waveforms
    nchan = size(in{1}, 2);

    % first, filter the waveforms
    for n=1:length(in)
        cur_waveform = in{n};
        for m=1:nchan
            cur_waveform(:, m) = ...
                filter(coeffs{1}, coeffs{2}, cur_waveform(:, m));
        end
        out{n} = cur_waveform;
    end

    % now whiten the waveforms temporally
    for n=1:length(out)
        cur_waveform = out{n};
        for m=1:nchan
            cur_waveform(:, m) = ...
                WhitenTraceInTime(cur_waveform(:, m), old_acfs{m}, reg_const);
        end
        out{n} = cur_waveform;
    end

    % now whiten the waveforms spatially, unless there's only one channel
    if nchan == 1
        return;
    end
    for n=1:length(out)
        cur_waveform = out{n};
        cur_waveform = ...
            WhitenTraceInSpace(cur_waveform, old_cov, reg_const);
        out{n} = cur_waveform;
    end
end
