%==========================================================================
% Postprocessing Step 1: Sonification
%
% Play back the reconstructed signal with Gaussian noise added in the left
% channel
% Play back the original (whitened) signal in the right channel
% - Correct matches will sound like clicks in the center.
% - False positives will sound like clicks only on the left
% - False negatives will sound like clicks only on the right

function SonificationStage
global params dataobj;
UpdateStage(@SonificationStage);

fprintf('***Postprocessing Step 1: Sonification\n'); %%@New

%Create reconstruction - add noise with variance scaled to num of channels
reconstructedclean = zeros(dataobj.whitening.nsamples,1);

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

%plot results
%%@make only if calibration mode
if (params.general.calibration_mode)
    SonificationPlot;
end

fprintf('***Done postprocessing step 1!\n\n');