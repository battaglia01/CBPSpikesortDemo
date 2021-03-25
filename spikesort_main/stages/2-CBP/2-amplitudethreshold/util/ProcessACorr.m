function [dts inds] = ProcessACorr(spiketimes, t0, t1, varargin)
    dropzero = true;
    ProcessXCorr(spiketimes, spiketimes, t0, t1, dropzero, varargin{:});
end
