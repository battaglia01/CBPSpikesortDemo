%% ----------------------------------------------------------------------------------
% CBP Step 4: Re-estimate waveforms
%
% Calibration for CBP waveforms:
% If recovered waveforms differ significantly from initial waveforms, then algorithm
% has not yet converged.  Execute this and go back to re-run CBP:
%     init_waveforms = waveforms;

function WaveformReestimationStage
global params dataobj;

fprintf('***CBP step 4: Re-estimate waveforms\n'); %%@New

CBPinfo = dataobj.CBPinfo;

% Compute waveforms using regression, with interpolation (defaults to cubic spline)
nlrpoints = (params.rawdata.waveform_len-1)/2;
CBPinfo.waveforms = cell(size(CBPinfo.spike_times));
for i = 1:numel(CBPinfo.spike_times)
    %%Is this why? You can only increase the threshold, not lower it
    sts = CBPinfo.spike_times{i}(CBPinfo.spike_amps{i} > CBPinfo.amp_thresholds(i)) - 1;
    CBPinfo.waveforms{i} = CalcSTA(dataobj.whitening.data', sts, [-nlrpoints nlrpoints]);
end

%%@ Move this
% Compare updated waveforms to initial estimates
%*** Hide this stuff somewhere else!
if (params.general.calibration_mode)
  num_waveforms = length(CBPinfo.waveforms);
  cols= hsv(num_waveforms);
  nchan=size(dataobj.whitening.data,1);
    AddCalibrationTab('Waveform Review');
    nc = ceil(sqrt(num_waveforms));
    nr = ceil(num_waveforms / nc);
    chSpace = 13; %**magic number, also in VisualizeClustering
    spacer = ones(size(CBPinfo.waveforms{1},1), 1) * ([1:nchan]-1)*chSpace;
    for i = 1:num_waveforms
        subplot(nr, nc, i); cla;
        inith = plot(reshape(dataobj.clustering.init_waveforms{i},[],nchan)+spacer, 'k');
        hold on
        finalh = plot(reshape(CBPinfo.waveforms{i},[],nchan)+spacer, 'Color', cols(i,:));
        hold off
        set(gca,'Xlim',[1, size(spacer,1)]);
        err = norm(dataobj.clustering.init_waveforms{i} - CBPinfo.waveforms{i})/...
              norm(CBPinfo.waveforms{i});
        title(sprintf('cell %d, change=%.0f%%', i, 100*err))
        legend([inith(1) finalh(1)], {'Initial', 'New'});
    end
end

dataobj.CBPinfo = CBPinfo;

fprintf('***Done CBP step 4.\n')
CBPNext('SonificationStage');
