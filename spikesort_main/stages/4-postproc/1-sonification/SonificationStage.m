<<<<<<< HEAD
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
y = zeros(length(dataobj.rawdata.data)*params.sonify.time_stretch,1);
fs = round(1/dataobj.rawdata.dt);

%Add spikes
for n=1:length(dataobj.CBPinfo.spike_times)
    currspikes = dataobj.CBPinfo.spike_times{n};
    curramps = dataobj.CBPinfo.spike_amps{n};
    for m=1:length(currspikes)-1
        sampbegin = params.sonify.time_stretch*round(currspikes(m));
        if(sampbegin+fs*params.sonify.note_duration < length(y))
            %waveforms
            mono_waveform=sum(dataobj.CBPinfo.waveforms{n},2);
            sound_snippet = curramps(m).*mono_waveform;
            y(sampbegin:sampbegin+length(mono_waveform)-1) = y(sampbegin:sampbegin+length(mono_waveform)-1) + sound_snippet;
            
            %notes
%             sound_snippet = sin(2*pi*params.sonify.base_freq * (params.sonify.ratios(n)/params.sonify.ratios(1))*(0:1/fs:params.sonify.note_duration));
%             sound_window = hanning(length(sound_snippet)*2,'periodic')';
%             sound_window = sound_window((length(sound_snippet)+1):end);
%             sound_snippet = sound_snippet .* sound_window .* curramps(m) * 2;
%             y(sampbegin:sampbegin+fs*params.sonify.note_duration) = y(sampbegin:sampbegin+fs*params.sonify.note_duration) + sound_snippet';
        end
    end
end

rd = sum(dataobj.whitening.data,1)';
numsamps = min(fs*params.sonify.sound_duration,length(rd));

y = [y(1:numsamps) rd(1:numsamps)];

soundsc(y,fs);

dataobj.sonify.soundout = y;
parout = params;

=======
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

>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc
fprintf('***Done postprocessing step 1!\n\n');