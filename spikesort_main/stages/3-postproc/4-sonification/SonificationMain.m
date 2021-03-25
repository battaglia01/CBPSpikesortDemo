%==========================================================================
% Postprocessing Step 3: Sonification
%
% Play back the reconstructed signal with Gaussian noise added in the left
% channel
% Play back the original (whitened) signal in the right channel
% - Correct matches will sound like clicks in the center.
% - False positives will sound like clicks only on the left
% - False negatives will sound like clicks only on the right

function SonificationMain
global CBPdata params CBPInternals;

% Create reconstruction - add noise with variance scaled to num of channels
reconstructedclean = zeros(CBPdata.whitening.nsamples,1);

% Get thresholded spike traces
spike_traces_thresholded = CBPdata.waveform_refinement.spike_traces_thresholded;

% Add spike traces together
for n=1:length(spike_traces_thresholded)
    reconstructedclean = reconstructedclean ...
                         + sum(spike_traces_thresholded{n}, 2);
end

reconstructed = reconstructedclean + randn(CBPdata.whitening.nsamples,1) ...
                                     * sqrt(CBPdata.whitening.nchan);

% Mix original channels from whitening stage to one channel
orig = sum(CBPdata.whitening.data,1)';

% Put results in CBPdata
CBPdata.sonification = [];
CBPdata.sonification.reconstructedclean = reconstructedclean;
CBPdata.sonification.reconstructed = reconstructed;
CBPdata.sonification.orig = orig;
