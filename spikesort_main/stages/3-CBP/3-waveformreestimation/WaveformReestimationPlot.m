function WaveformReestimationPlot(disable)
    global params dataobj;

    if nargin == 1 & ~disable
        DisableCalibrationTab('Waveform Review');
        return;
    end


    num_waveforms = length(dataobj.CBPinfo.final_waveforms);
    cols= hsv(num_waveforms);
    nchan=size(dataobj.whitening.data,1);
    
    AddCalibrationTab('Waveform Review');
    nc = ceil(sqrt(num_waveforms));
    nr = ceil(num_waveforms / nc);
    chSpace = 13; %**magic number, also in PlotClusters
    spacer = ones(size(dataobj.CBPinfo.final_waveforms{1},1), 1) * ([1:nchan]-1)*chSpace;
    for i = 1:num_waveforms
        subplot(nr, nc, i); cla;
        inith = plot(reshape(dataobj.CBPinfo.init_waveforms{i},[],nchan)+spacer, 'k');
        hold on
        finalh = plot(reshape(dataobj.CBPinfo.final_waveforms{i},[],nchan)+spacer, 'Color', cols(i,:));
        hold off
        set(gca,'Xlim',[1, size(spacer,1)]);
        err = norm(dataobj.CBPinfo.init_waveforms{i} - dataobj.CBPinfo.final_waveforms{i})/...
              norm(dataobj.CBPinfo.final_waveforms{i});
        title(sprintf('cell %d, change=%.0f%%', i, 100*err))
        legend([inith(1) finalh(1)], {'Initial', 'New'});
    end
end