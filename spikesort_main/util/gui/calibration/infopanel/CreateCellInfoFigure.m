% Creates the Cell Info figure.
% If you want to create the cell info figure in the program,
% you usually want to call GetCellInfoFigure, not this.

function f = CreateCellInfoFigure
    global CBPdata params CBPInternals;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some reusable params
    checkboxsize = 20;
    checkboxmargin = 50;
    num_waveforms = params.plotting.max_num_cells;
        
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
    set(f, 'Resize', 'off');

    figwidth = 200;
    figpos = get(gcf,'InnerPosition');
    scrsz =  get(0,'ScreenSize');
    set(f, 'InnerPosition', [scrsz(3)/2-figwidth/2, figpos(2), figwidth, figpos(4)]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up panels and scroll panel
    % get new adjusted figpos again
    figpos = get(gcf,'InnerPosition');
    panelwidth = figpos(3);
    panelheight = checkboxsize * num_waveforms ...
                    + checkboxsize * 2; % pad with some extra spacing

    % set up inner panel. easier to determine the position in pixels, 
    % since we've specified the figure position in pixels, so we'll do
    % that.
    % in the "figpos(4)*.9-panelheight," we multiply by that .9 to leave
    % 10% for the buttons below
    innerpanelpos =   [0            figpos(4)*.9-panelheight ...
                       panelwidth   panelheight];
    innerpanel = uipanel(f, 'Units', 'pixels', ...
                            'BorderType', 'none', ...
                            'OuterPosition', innerpanelpos);
    
    % set up outer panel, this time in normalized units, so that there is
    % 10% left for buttons below
    outerpanelpos = [0 .10 1 .90];
    if panelheight > figpos(4) * .9
        scrolltype = "vert";
    else
        scrolltype = "none";
    end
    outerscrollpanel = uiscrollpanel(innerpanel, scrolltype, 0, panelheight - figpos(4)*.9, ...
                                     'Units', 'Normalized', ...
                                     'Position', outerpanelpos);
    % Draw everything
    pause(0.01);
    drawnow;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Buttons
    % Change hScrollPanel units to "Normalized," carve out a 10% space at
    % bottom
    
    % initialize figure's appdata tmp_cells_to_plot equal to the current
    % one
    setappdata(f, 'tmp_cells_to_plot', CBPInternals.cells_to_plot);

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
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draw check boxes
%
    % start out with "num_waveforms" being the number of clustering
    % waveforms, but as we add waveforms in the waveform_refinement stage
    % (or ground truth), add more cell plot checkboxes
    %%@ Actually we're now using the params.plotting.max_cells parameter.
    %%@ But this is left for reference
% 	num_waveforms = params.clustering.num_waveforms;
%     if isfield(CBPdata, "waveform_refinement") && ...
%        isfield(CBPdata.waveform_refinement, "num_waveforms")
%         num_waveforms = max(num_waveforms, ...
%                             CBPdata.waveform_refinement.num_waveforms);
%     end
%     if isfield(CBPdata, "ground_truth") && ...
%        isfield(CBPdata.ground_truth, "true_spike_class")
%         num_waveforms = max(num_waveforms, ...
%                             length(unique(CBPdata.ground_truth.true_spike_class)));
%     end
    for n=1:num_waveforms
        % check if this is being plotted
        if ismember(n, CBPInternals.cells_to_plot)
            plotted = true;
        else
            plotted = false;
        end

        % now add toggle
        % in panelheight-checkboxsize*(n+1), the (n+1) gives us extra space
        cpos = [checkboxmargin  panelheight-checkboxsize*(n+1) ...
                checkboxsize    checkboxsize];
        c = ToggleCheckbox(innerpanel, 'Units', 'pixels', ...
                                      'BackgroundColor', params.plotting.cell_color(n), ...
                                      'Position', cpos, ...
                                      'UserData', plotted);
        setappdata(c, 'togglecallback', @() UpdatePlotCells(n, c));

        % add text label
        tpos = [checkboxmargin+5+checkboxsize               panelheight-checkboxsize*(n+1) ...
                panelwidth-checkboxsize-5-checkboxmargin    checkboxsize];
        t = uicontrol(innerpanel, 'Style', 'text', ...
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
% Cleanup
    % reset the look and feel
    %%@ javax.swing.UIManager.setLookAndFeel(CBPInternals.original_LnF);
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
    if CBPInternals.curr_selected_tab_stage.replotoncellchange
        CBPStagePlot(CBPInternals.curr_selected_tab_stage);
    end
    
    %  first check if the figure exists before trying to close - useful in
    %  the event the button is double clicked
    if ishghandle(f)
        close(f);
    end
end

function CancelInfo(f)
    %  first check if the figure exists before trying to close - useful in
    %  the event the button is double clicked
    if ishghandle(f)
        close(f);
    end
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
