function SubpopulationPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DisableCalibrationTab('Subpopulations');
        return;
    end
    
% -------------------------------------------------------------------------
% Set up basics
    %%@ note - we aren't using any of this! Putting "if false" just to keep
    %%it for reference
    if false
        [est_matches true_matches] = GreedyMatchTimes(dataobj.CBPinfo.spike_times, ...
            dataobj.ground_truth.true_sp, params.postproc.spike_location_slack);

        % Complete misses (missed even at 0 threshold)
        completemisses = cell(size(dataobj.ground_truth.true_sp));
        for i = 1:length(dataobj.ground_truth.true_sp)
            completemisses{i} = dataobj.ground_truth.true_sp{i}(true_matches{i} == 0);
        end

        % All FPs (with 0 threshold)
        allfps = cell(size(dataobj.CBPinfo.spike_times));
        for i = 1:length(dataobj.CBPinfo.spike_times)
            allfps{i} = dataobj.CBPinfo.spike_times{i}(est_matches{i} == 0);
        end
    end

    
% -------------------------------------------------------------------------
% Plot Snippets
    % For example; more complicated selections of spikes like misses or FPs
    % with given threshold can also be calculated
    % TODO PHLI: automate this.
    % desiredspiketimes = cell2mat(allfps);         % Pick one or the other...
    % desiredspiketimes = cell2mat(completemisses); % Pick one or the other...
    desiredspiketimes = cell2mat(dataobj.CBPinfo.spike_times);
    
    % Now find and plot the relevant snippets
    snipindices = FindSnippets(desiredspiketimes, dataobj.CBPinfo.snippet_centers, dataobj.CBPinfo.snippets); % snippets just given as shorthand for calculating widths
    
    %%@merge ScrollSnippets here
    if isfield(dataobj.ground_truth, 'true_sp')
        ScrollSnippets(dataobj.CBPinfo.snippets, dataobj.CBPinfo.snippet_centers, ...
            'snipindices',  unique(snipindices(snipindices > 0)),  ...
            'cbp',          dataobj.CBPinfo.spike_times,        ...
            'cbpamp',       dataobj.CBPinfo.spike_amps,         ...
        ... %     'cbpampthresh', amp_thresholds,      ... % Could use amp_thresholds if we used that to pick snippets...
            'clust',        dataobj.clustering.spike_times_cl,     ...
        ... %     'recons',       recon_snippets,     ...
            'true',         dataobj.ground_truth.true_sp,     ...
            'dt',           dataobj.whitening.dt             ...
        );
    else
        ScrollSnippets(dataobj.CBPinfo.snippets, dataobj.CBPinfo.snippet_centers, ...
            'snipindices',  unique(snipindices(snipindices > 0)),  ...
            'cbp',          dataobj.CBPinfo.spike_times,        ...
            'cbpamp',       dataobj.CBPinfo.spike_amps,         ...
        ... %     'cbpampthresh', amp_thresholds,      ... % Could use amp_thresholds if we used that to pick snippets...
            'clust',        dataobj.clustering.spike_times_cl,     ...
        ... %     'recons',       recon_snippets
            'dt',           dataobj.whitening.dt               ...
        );
	end
end
