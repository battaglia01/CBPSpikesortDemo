function PCAComparisonPlot(command)
    global params dataobj;
    
    if nargin == 1 & isequal(command, 'disable')
        DisableCalibrationTab('PCA Comparison');
        DisableCalibrationTab('Post-Analysis Waveforms');
        return;
    end

% -------------------------------------------------------------------------
% Check that we have ground truth
    if ~isfield(dataobj.ground_truth, 'true_sp')
        t=AddCalibrationTab('PCA Comparison');
        cla('reset');
        axis off;
        uicontrol('Style','text',...
        'Parent',t,...
        'Units','normalized',...
        'Position',[0 0 1 1],...
        'HorizontalAlignment','center',...
        'FontSize',36,...
        'ForegroundColor','r',...
        'String',[10 10 'No Ground Truth!' 10 10 'Nothing to plot']);
        return;
    end
    
% -------------------------------------------------------------------------
% Set up basics
                        
    %set up local vars
    XProj = dataobj.ground_truth.XProjstar;
    assignments = dataobj.ground_truth.true_spike_class;
    X = dataobj.ground_truth.Xstar;
    nchan = size(dataobj.whitening, 1);
    threshold = params.clustering.spike_threshold;  %spike threshold

    % XProj : snippet x PC-component matrix of projections
    % assignments : vector of class assignments
    % X : time x snippet-index matrix of data
    if (~exist('marker', 'var'))
        marker = '.';
    end

    
    N_inds = unique(assignments);
    N = length(N_inds);
    %%@Mike's note regarding above:
    %Now, it may be possible that we have more "true" spike classes than we
    %chose to create spike clusters in the beginning. If this is the case, 
    %then we will have some true spikes assigned to cluster number "0". We
    %will print a warning and drop those here.
    if any(N_inds==0)
        fprintf('NOTE: There are more ground truth spike classes than CBP spike classes.\n')
        fprintf('To fix this, increase params.num_waveforms to at least %d\n', ...
            length(unique(dataobj.ground_truth.true_spike_class)))
        N_inds = N_inds(N_inds ~= 0);
        N = length(N_inds);
    end
    
    colors = hsv(max(dataobj.clustering.assignments)); %%@Match colors to other PC plot
    centroids = zeros(size(X, 1), N);
    projCentroids = zeros(size(XProj,2), N);
    counts = zeros(N, 1);
    distances = zeros(size(X,2),1);
    for i=1:N
      %check that we aren't at an "unassigned" ground truth spike
      %with no corresponding cluster
      if N_inds(i) == 0
          continue;
      end
      
      spikeIinds = find(assignments==N_inds(i));
      if isempty(spikeIinds)
          continue;
      end
      centroids(:, N_inds(i)) = mean(X(:, spikeIinds), 2);
      projCentroids(:,N_inds(i)) = mean(XProj(spikeIinds,:)', 2);
      counts(N_inds(i)) = length(spikeIinds);
      distances(spikeIinds) = sqrt(sum((XProj(spikeIinds,:)' - ...
           repmat(projCentroids(:,N_inds(i)),1,counts(N_inds(i)))).^2))';
    end

% -------------------------------------------------------------------------
% Plot PCs (Tab 1)
    AddCalibrationTab('PCA Comparison');
    cla('reset');
    hold on;

    for i=1:N     %plot central cluster first
        ind = N_inds(i);
        idx = ((assignments == ind) & (distances<threshold));
        if isempty(idx)
            continue;
        end
        plot(XProj(idx, 1), XProj(idx, 2), ...
             '.', 'Color', 0.5*colors(ind, :)+0.5*[1 1 1], ...
             'Marker', marker, 'MarkerSize', 8);
    end
    for i=1:N     %plot outliers second
        ind = N_inds(i);
        idx = ((assignments == ind) & (distances>=threshold));
        if isempty(idx)
            continue;
        end
        plot(XProj(idx, 1), XProj(idx, 2), ...
             '.', 'Color', 0.5*colors(ind, :)+0.5*[1 1 1], ...
             'Marker', marker, 'MarkerSize', 8);
    end
    centhandles = [];
    for i=1:N
      ind = N_inds(i);
      zsc = norm(projCentroids(:,ind));
      centhandles(i) = plot(projCentroids(1,ind), projCentroids(2,ind), 'o', ...
          'MarkerSize', 9, 'LineWidth', 2, 'MarkerEdgeColor', 'black', ...
          'MarkerFaceColor', colors(ind,:), 'DisplayName', ...
          ['cell ' num2str(ind) ', amplitude=' num2str(zsc)]);
    end
    xl = get(gca, 'XLim'); yl = get(gca, 'YLim');
    plot([0 0], yl, '-', 'Color', 0.8 .* [1 1 1]);
    plot(xl, [0 0], '-', 'Color', 0.8 .* [1 1 1]);
    th=linspace(0, 2*pi, 64);
    nh= plot(threshold*sin(th),threshold*cos(th), 'k', 'LineWidth', 2, ...
        'DisplayName', sprintf('spike threshold = %.1f',threshold));
    legend([nh centhandles]);
    axis equal
    hold off
    font_size = 12;
    set(gca, 'FontSize', font_size);
    xlabel('PC 1'); ylabel('PC 2');
    title(sprintf('Clustering result (%d clusters)', N));

% -------------------------------------------------------------------------
% Plot the time-domain snippets (Tab 2)
    AddCalibrationTab('Post-Analysis Waveforms');
    hold on;
    nc = ceil(sqrt(N)); nr=ceil((N)/nc);
    chOffset = 13; %**Magic vertical spacing between channels
    wlen = size(X, 1) / nchan;
    MAX_TO_PLOT = 1e2;
    yrg = zeros(N,1);
    for i=1:N
        ind = N_inds(i);
        Xsub = X(:, assignments == ind);
        if isempty(Xsub), continue; end
        if (size(Xsub, 2) > MAX_TO_PLOT)
            Xsub = Xsub(:, randsample(size(Xsub, 2), MAX_TO_PLOT, false));
        end
        Xsub = Xsub + chOffset*floor(([1:(nchan*wlen)]'-1)/wlen)*ones(1,size(Xsub,2));
        centroid = centroids(:,ind) + chOffset*floor(([1:(nchan*wlen)]'-1)/wlen);

        subplot(nc, nr, i); cla;
        hold on;
        plot(reshape(Xsub,wlen,[]), 'Color', 0.25*colors(ind,:)+0.75*[1 1 1]);
        plot(reshape(centroid,wlen,[]), 'Color', colors(ind,:), 'LineWidth', 2);
        xlim([0, wlen+1]);
        yrg(i) = (max(Xsub(:))-min(Xsub(:)));
        axis tight; %%@fixes display issues
        set(gca, 'FontSize', font_size);
        xlabel('time (samples)');
        title(sprintf('cell %d, snr=%.1f', ind, norm(centroids(:,ind))/sqrt(size(centroids,1))));
        hold off
    end

    % make axis ticks same size on all subplots
    mxYrg = max(yrg);
    for i = 1:N
      subplot(nc,nr,i);
      ylim=get(gca,'Ylim');
      ymn = mean(ylim);
      yrg = ylim(2)-ylim(1);
      set(gca,'Ylim', ymn + (ylim - ymn)*(mxYrg/yrg));
    end

    ip = centroids'*centroids;
    dist2 = repmat(diag(ip),1,size(ip,2)) - 2*ip + repmat(diag(ip)',size(ip,1),1) +...
            diag(diag(ip));
    fprintf(1,'Distances between waveforms (diagonal is norm): \n');
    disp(sqrt(dist2/size(centroids,1)));

    return
