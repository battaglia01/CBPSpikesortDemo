%==========================================================================
% Postprocessing Step 1: Sonification
%
% Play back the measured spike waveform, stretched in time, but using
% musical notes of different frequencies to make clear when a spike is
%
% params includes:
%  - params.sonify.base_freq : lowest note in the "chord" being played
%  - params.sonify.ratios : harmonics of this note
%  - click_duration : used to determine number of principal components to
%      use for clustering
%  - params.sonify.time_stretch : rate at which the spike train is slowed down in time
%  - params.sonify.sound_duration : number of seconds of signal being played back

function SonificationStage
global params dataobj;

fprintf('***Postprocessing Step 1: Sonification\n'); %%@New

%Create template for waveform
y = zeros(1,length(dataobj.rawdata.data)*params.sonify.time_stretch);
fs = round(1/dataobj.rawdata.dt);
for n=1:length(dataobj.CBPinfo.spike_times)
    currspikes = dataobj.CBPinfo.spike_times{n};
    for m=1:length(currspikes)-1
        sampbegin = params.sonify.time_stretch*round(currspikes(m));
        if(sampbegin+fs*params.sonify.note_duration < length(y))
            sound_snippet = sin(2*pi*params.sonify.base_freq * (params.sonify.ratios(n)/params.sonify.ratios(1))*(0:1/fs:params.sonify.note_duration));
            sound_snippet = sound_snippet .* hanning(length(sound_snippet))';
            y(sampbegin:sampbegin+fs*params.sonify.note_duration) = y(sampbegin:sampbegin+fs*params.sonify.note_duration) + sound_snippet;
        end
    end
end

soundsc(y(1:fs*params.sonify.sound_duration),fs);

dataobj.sonify.soundout = y;
parout = params;

fprintf('***Done postprocessing step 1!\n\n');