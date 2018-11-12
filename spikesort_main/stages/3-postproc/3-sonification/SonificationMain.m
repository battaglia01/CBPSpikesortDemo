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
global params dataobj;

%Create reconstruction - add noise with variance scaled to num of channels
reconstructedclean = zeros(dataobj.whitening.nsamples,1);

%Create final spike traces
dataobj.CBPinfo.spike_traces_final = CreateSpikeTraces(dataobj.CBPinfo.spike_times, dataobj.CBPinfo.spike_amps, ...
        dataobj.CBPinfo.final_waveforms, dataobj.whitening.nsamples, dataobj.whitening.nchan);

%add spike traces together
for n=1:length(dataobj.CBPinfo.spike_traces_init)
    reconstructedclean = reconstructedclean + sum(dataobj.CBPinfo.spike_traces_final{n},2);
end

reconstructed = reconstructedclean + randn(dataobj.whitening.nsamples,1) * sqrt(dataobj.whitening.nchan);

%mix original channels from whitening stage to one channel
orig = sum(dataobj.whitening.data,1)';

%put results in dataobj
dataobj.sonification = [];
dataobj.sonification.reconstructedclean = reconstructedclean;
dataobj.sonification.reconstructed = reconstructed;
dataobj.sonification.orig = orig;