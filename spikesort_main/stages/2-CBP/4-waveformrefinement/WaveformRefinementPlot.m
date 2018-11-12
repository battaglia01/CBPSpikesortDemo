function WaveformRefinementPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command,'disable')
        DeleteCalibrationTab('Waveform Refinement');
        return;
    end

    dt = dataobj.whitening.dt;
    num_waveforms = length(dataobj.CBPinfo.final_waveforms);
    cols = hsv(num_waveforms);
    nchan = size(dataobj.whitening.data,1);

    CreateCalibrationTab('Waveform Refinement', 'WaveformRefinement');
    nc = ceil(sqrt(num_waveforms));
    nr = ceil(num_waveforms / nc);
    chSpace = 13; %**magic number, also in PlotClusters
    spacer = ones(size(dataobj.CBPinfo.final_waveforms{1},1), 1) * ([1:nchan]-1)*chSpace;
    t_axis = (1:size(spacer,1))*dt*1000;
    for i = 1:num_waveforms
        subplot(nr, nc, i); cla;
        inith = plot(t_axis, reshape(dataobj.CBPinfo.init_waveforms{i},[],nchan)+spacer, 'k');
        hold on
        finalh = plot(t_axis, reshape(dataobj.CBPinfo.final_waveforms{i},[],nchan)+spacer, 'Color', cols(i,:));
        hold off
        xlim(dt*1000*[1, size(spacer,1)]);
        err = norm(dataobj.CBPinfo.init_waveforms{i} - dataobj.CBPinfo.final_waveforms{i})/...
              norm(dataobj.CBPinfo.final_waveforms{i});
        xlabel('Time (msec)')
        title(sprintf('Cell %d, Change=%.0f%%', i, 100*err))
        legend([inith(1) finalh(1)], {'Initial', 'New'});
    end
end
