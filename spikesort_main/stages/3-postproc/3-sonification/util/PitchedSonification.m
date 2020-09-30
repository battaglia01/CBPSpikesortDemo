function PitchedSonification
    global CBPdata;
    CBPdata.sonification.pitched_waveforms = {};
    pad = 3;
    for n=1:length(CBPdata.CBP.final_waveforms)
        tmp = CBPdata.CBP.final_waveforms{n};
        tmp = fft(tmp,length(tmp)*pad);
        tmpmax = norm(tmp,Inf);
        tmp = tmp/tmpmax;
        %tmp = tmp .* abs(tmp).^50;
        tmp = tmp .* (abs(tmp) == max(abs(tmp)));
        tmp = tmp*tmpmax;
        f_tmp = tmp;
        tmp = real(ifft(tmp,length(tmp)));
        tmp = fftshift(tmp);
        %tmp = tmp(1:length(tmp)/pad);
        tmp = tmp.*blackman(length(tmp));
        
%         tmpmax = norm(tmp,2);
%         tmp = tmp/tmpmax;
%         ntmp = tmp;
%         for m=1:40
%             ntmp = conv(ntmp,tmp);
%         end
%         tmp = ntmp;
        CBPdata.sonification.pitched_waveforms{n} = tmp;
    end
    
    pitched_traces = CreateSpikeTraces(...
    CBPdata.CBP.spike_time_array, CBPdata.CBP.spike_amps, ...
    CBPdata.sonification.pitched_waveforms, CBPdata.whitening.nsamples, ...
    CBPdata.whitening.nchan);


    %add spike traces together
    pitched_sum = zeros(CBPdata.whitening.nsamples,1);
    for n=1:length(CBPdata.sonification.pitched_waveforms)
        pitched_sum = pitched_sum + sum(pitched_traces{n},2);
    end

    fs = 1/CBPdata.whitening.dt;
    mikesoundsc(pitched_sum, fs);
    figure(12345);
    clf;
    plot(tmp);
    hold all;
    plot(CBPdata.CBP.final_waveforms{n});
end
