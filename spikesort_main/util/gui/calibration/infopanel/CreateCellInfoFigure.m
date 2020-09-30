% Creates the Cell Info figure.
% If you want to create the cell info figure in the program,
% you usually want to call GetCellInfoFigure, not this.

function f = CreateCellInfoFigure
    global CBPdata params CBPInternals;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up figure
%
    % Set look and feel. Taken from
    % http://undocumentedmatlab.com/blog/modifying-matlab-look-and-feel/
    %%@ javax.swing.UIManager.setLookAndFeel('javax.swing.plaf.metal.MetalLookAndFeel');
    %%@ ^^ NOTE: Metal no longer works on Mac R2019, so just use the default

    %If figure doesn't already exist, create it
    f = figure(params.plotting.cell_info_figure);
    clf reset;
    f.NumberTitle = 'off';
    f.Name = 'Cell Info';
    set(f, 'ToolBar', 'none', 'MenuBar', 'none');

    figwidth = 200;
    figpos = get(gcf,'InnerPosition');
    scrsz =  get(0,'ScreenSize');
    set(f, 'InnerPosition', [scrsz(3)/2-figwidth/2, figpos(2), figwidth, figpos(4)]);

    % initialize figure's appdata tmp_cells_to_plot equal to the current
    % one
    setappdata(f, 'tmp_cells_to_plot', CBPInternals.cells_to_plot);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draw panel and check boxes
%
    % some reusable params
    checkboxsize = 20;
    checkboxmargin = 50;

    % get new adjusted figpos again
    figpos = get(gcf,'InnerPosition');
    panelwidth = figpos(3);
    panelheight = checkboxsize*params.clustering.num_waveforms;

    % adding a safety margin seems to get rid of spurious horizontal
    % scrollbars. (We get rid it when adding the scrollpane anyway)
    safetymargin = 50;
    panelpos = [safetymargin                figpos(4)-panelheight ...
                panelwidth-2*safetymargin   panelheight];
    mainpanel = uipanel(f, 'Units', 'pixels', ...
                           'OuterPosition', panelpos);

    % start out with "num_waveforms" being the number of clustering
    % waveforms, but as we add waveforms in the waveformrefinement stage
    % (or ground truth), add more cell plot checkboxes
	num_waveforms = params.clustering.num_waveforms;
    if isfield(CBPdata, "waveformrefinement") && ...
       isfield(CBPdata.waveformrefinement, "num_waveforms")
        num_waveforms = max(num_waveforms, ...
                            CBPdata.waveformrefinement.num_waveforms);
    end
    if isfield(CBPdata, "groundtruth") && ...
       isfield(CBPdata.groundtruth, "true_spike_class")
        num_waveforms = max(num_waveforms, ...
                            length(unique(CBPdata.groundtruth.true_spike_class)));
    end
    for n=1:num_waveforms
        % check if this is being plotted
        if ismember(n, CBPInternals.cells_to_plot)
            plotted = true;
        else
            plotted = false;
        end

        % now add toggle
        cpos = [checkboxmargin  panelheight-checkboxsize*n ...
                checkboxsize    checkboxsize];
        c = ToggleCheckbox(mainpanel, 'Units', 'pixels', ...
                                      'BackgroundColor', params.plotting.cell_color(n), ...
                                      'Position', cpos, ...
                                      'UserData', plotted);
        setappdata(c, 'togglecallback', @() UpdatePlotCells(n, c));

        % add text label
        tpos = [checkboxmargin+5+checkboxsize               panelheight-checkboxsize*n ...
                panelwidth-checkboxsize-5-checkboxmargin    checkboxsize];
        t = uicontrol(mainpanel,  'Style', 'text', ...
                                  'String', "Cell #" + n, ...
                                  'Units', 'pixels', ...
                                  'Position', tpos, ...
                                  'HorizontalAlignment', 'left', ...
                                  'FontUnits', 'Normalized', ...
                                  'FontSize', 0.8);
    end

    % draw everything
    pause(0.01);
    drawnow;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scroll panel
% Taken from https://undocumentedmatlab.com/blog/scrollable-gui-panels
    % Get the panel's underlying JPanel object reference
    jPanel = mainpanel.JavaFrame.getGUIDEView.getParent;

    % Embed the JPanel within a new JScrollPanel object
    jScrollPanel = javaObjectEDT(javax.swing.JScrollPane(jPanel));

    % Remove the JScrollPane border-line
    jScrollPanel.setBorder([]);

    % Place the JScrollPanel in same GUI location as the original panel
    hParent = mainpanel.Parent;

    % redo figpos as we've changed it from before when resizing
    %set(f, 'Units', 'normalized');
    figpos = get(f,'InnerPosition');
    figpos(1:2) = 0;
    [hjScrollPanel, hScrollPanel] = javacomponent(jScrollPanel, figpos, hParent);
    set(hScrollPanel, 'Units', 'normalized'); %%@ Do we need this?

    % Ensure that the scroll-panel and contained panel have linked visibility
    hLink = linkprop([mainpanel,hScrollPanel],'Visible');
    setappdata(mainpanel,'ScrollPanelVisibilityLink',hLink);

    % Draw everything and scroll to top left
    pause(0.01);
    drawnow;
    jScrollPanel.getViewport.setViewPosition(java.awt.Point(0,0));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Buttons
    % Change hScrollPanel units to "Normalized," carve out a 10% space at
    % bottom
    set(hScrollPanel, 'Units', 'normalized');
    scrpos = get(hScrollPanel, 'Position');
    scrpos(2) = scrpos(2) + .1;
    scrpos(4) = .9;
    set(hScrollPanel, 'Position', scrpos);

    % Add "Save" and "Cancel" buttons
    savebutn = uicontrol(f, 'Tag', 'cellinfopanel_save', ...
                            'Style', 'pushbutton', ...
                            'FontSize', 14, ...
                            'String', 'Save', ...
                            'Units', 'normalized', ...
                            'Position', [0 0 0.5 0.1], ...
                            'Callback', @(varargin) SaveInfo(f));
    cancbutn = uicontrol(f, 'Tag', 'cellinfopanel_cancel', ...
                            'Style', 'pushbutton', ...
                            'FontSize', 14, ...
                            'String', 'Cancel', ...
                            'Units', 'normalized', ...
                            'Position', [0.5 0 0.5 0.1], ...
                            'Callback', @(varargin) CancelInfo(f));

    % Draw everything
    pause(0.01);
    drawnow;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cleanup
    % reset the look and feel
    %%@ javax.swing.UIManager.setLookAndFeel(CBPInternals.originalLnF);
%%@ ^^ NOTE: Metal no longer works on Mac R2019, so not necessary
end

function SaveInfo(f)
    global CBPInternals;

    % first check if anything has changed, and set CBPInternals correctly
    tmp_cells_to_plot = getappdata(f, 'tmp_cells_to_plot');
    if ~isequal(tmp_cells_to_plot, CBPInternals.cells_to_plot)
        CBPInternals.cells_to_plot = tmp_cells_to_plot;
    end

    % if stuff has changed, then iterate through all stages, set the ones
    % with replotoncellchange=true to have needsreplot=true
    for n=1:length(CBPInternals.stages)
        stg = CBPInternals.stages{n};
        if stg.replotoncellchange
            stg.needsreplot = true;
            CBPInternals.stages{n} = stg;
        end
    end

    % lastly, if currently selected tab is from a stage that also replots
    % on cell change, replot right away
    if CBPInternals.currselectedtabstage.replotoncellchange
        CBPStagePlot(CBPInternals.currselectedtabstage);
    end
    close(f);
end

function CancelInfo(f)
    close(f);
end

function UpdatePlotCells(cellnum, cellobj)
    val = get(cellobj, 'UserData');
    tmp_cells_to_plot = getappdata(gcf, "tmp_cells_to_plot");
    if val == 1
        tmp_cells_to_plot = unique([tmp_cells_to_plot cellnum]);
    else
        tmp_cells_to_plot = setdiff(tmp_cells_to_plot, cellnum);
    end
    setappdata(gcf, "tmp_cells_to_plot", tmp_cells_to_plot);
end
