% This function simultaneously plots many multi-channel lineseries at the
% It creates multiple plots for each channel of the lineseries, and then
% stores them all in a panel.
%
% This function is compatible with things like subplot and etc.
%
% The helper functions `multiplotxlabel`, `multiplotylabel`,
% `multiplottitle`, and `multiplotlegend` do what you expect.
%
% See also `multiplotsubfunc` and `multiplotsubignore` for functions that
% call to each subplot.
% 
% The arguments are either a panel and a cell array of plots, or just a
% cell array of plots (in which situation multiplot will make a container
% panel). The plots cell array has as elements a set of objects, each with
% the following attributes:
%        x: the x positions for the lineseries (uses 1:length(y) if not entered)
%        y: the lineseries heights for each value of x
%     args: the other arguments to pass to plot(...) as it is called
%     chan: the channel that this timeseries is on
% axisargs: arguments to pass to the axis object upon first creation (only
%           the first plot object is read)
%     type: `patch`, `rawplot`, or `plot` (latter is default)
%
% function panel = multiplot(panel, plots)
% function panel = multiplot(plots)
function panel = multiplot(varargin)
    if nargin > 1
        % panel given as first argument.
        % We are modifying an existing multiplot
        panel = varargin{1};
        plots = varargin{2};
        first_run = false;
    else
        % panel not given as first argument, so this is the first time
        % this is called.
        plots = varargin{1};
        first_run = true;
    end

    % iterate through plots, get correct number of channels
    usedchanarray = [0];
    for n=1:length(plots)
        if isfield(plots{n}, 'chan')
            % "header" is a special chan value for channel 1
            if isequal(plots{n}.chan, 'header')
                curchan = 1;
            else
                curchan = plots{n}.chan;
            end
            usedchanarray = unique([usedchanarray curchan]);
        else
            newchan = min(setdiff(1:(max(usedchanarray)+1), usedchanarray));
            plots{n}.chan = newchan;
            usedchanarray = unique([usedchanarray newchan]);
        end
    end
    chans = max(usedchanarray);

    % create panel if first run
    if first_run
        % create panel by using/creating temp axes for reference (which we
        % delete at end)
        % NOTE: axes created here if not already
        under_panel = gca;
        set(under_panel, 'Visible', 'on');
        xlabel(' ');
        ylabel(' ');
        title(' ');
        drawnow; %%@ PROBABLY NEED THIS ON
        pause(0.01);

        % create panel to have same position as axes, store position
        p = get(gca,'Position');
        o = get(gca,'OuterPosition');
        scaledpos = [(p(1)-o(1))/o(3), (p(2)-o(2))/o(4), ...
                     p(3)/o(3), p(4)/o(4)];
        panel = uipanel(get(under_panel, 'Parent'), 'Position', o, ...
                        'BorderType', 'none'); %%@ border goes here
        setappdata(panel, 'scaledpos', scaledpos);

        % make "under_panel" axes invisible, add reference to panel appdata
        set(under_panel, 'Visible', 'off');
        setappdata(panel, 'under_panel', under_panel);

        % create initial subplots
        ax = gobjects(1,chans);
        for n=1:chans
            new_r = chans;
            new_c = 1;
            new_ind = n;
            ax(new_ind) = subplot(new_r, new_c, new_ind, 'Parent', panel);
            setappdata(ax(n), 'patchesplotted', false);
            if isfield(plots{1}, 'axisargs')
                set(ax(n), plots{1}.axisargs{:});
            end
        end

        % lastly, create invisible under_subplot axes for titles and labels
        under_subplot = axes(panel, 'Visible', 'off', 'Position', scaledpos);
        setappdata(panel, 'under_subplot', under_subplot);
        currplots = {};
    else
        % otherwise, just get previously saved app data variables, and make sure
        % number of plots hasn't changed
        under_panel = getappdata(panel, 'under_panel');
        under_subplot = getappdata(panel, 'under_subplot');
        scaledpos = getappdata(panel, 'scaledpos');
        ax = getappdata(panel, 'mp_axes');
        currplots = getappdata(panel, 'currplots');

        assert(length(plots) == length(currplots), ...
               'ERROR - Number of plots cannot change on replot');
    end

    % do the plot!
    to_delete = gobjects(0);
    for n=1:length(plots)
        ind = plots{n}.chan;
        % if header, set 'ind' to 1 and set app data accordingly
        if isequal(ind, 'header')
            ind = 1;
            setappdata(panel, 'has_header', true);
            set(ax(1), 'Color', [0.9 0.9 0.9]);
            set(ax(1).YAxis, 'Visible', 'off');
            set(ax(1), 'XGrid', 'on');
        end

        % if it's a patch
        % currently we only plot these on the first_run, and assume they
        % don't change on subsequent replots
        if isfield(plots{n}, 'type') && isequal(plots{n}.type, 'patch')
            if first_run
                currplots{n} = patch(ax(ind), plots{n}.args{:});
            end

        % if it's a "rawplot", we only plot once and assume no changes
        %%@! should we call it something else besides "rawplot"?
        elseif isfield(plots{n}, 'type') && isequal(plots{n}.type, 'rawplot')
            if first_run
                if isfield(plots{n}, 'args')
                    tmp_args = plots{n}.args;
                else
                    tmp_args = {};
                end
                hold(ax(ind), 'all');
                currplots{n} = plot(ax(ind), plots{n}.x, plots{n}.y, plots{n}.args{:});
                hold(ax(ind), 'off');
            end

        % else it's a regular plot. queue existing plot #n for deletion,
        % plot new one
        else
            if ~first_run
                % already plotted delete the old plot
                to_delete(end+1) = currplots{n};
            end
            if isfield(plots{n}, 'args')
                tmp_args = plots{n}.args;
            else
                tmp_args = {};
            end
            hold(ax(ind), 'all');
            currplots{n} = plot(ax(ind), plots{n}.x, plots{n}.y, tmp_args{:});
            hold(ax(ind), 'off');
        end
    end

    % now delete old plots and save currplots
    if ~isempty(to_delete)
        % timer makes plotting smoother
        t = timer('TimerFcn', @(~,~) delete(to_delete), ...
                  'StopFcn', @(this,~) delete(this), ...
                  'StartDelay', 0.3);
        start(t);
    end
    setappdata(panel, 'currplots', currplots);

    % change labels
    %%@! may need to do this
    for n=1:chans
        % Adjust Y labels for overlap
        %if n ~= 1
            %yt = get(ax(n), 'YTickLabels');
            %yt(end) = [];
            %yt{1} = ['^{' yt{1} '}'];
            %yt{end} = ['_{' yt{end} '}'];
            %set(ax(n), 'YTickLabels', yt);
            %set(ax(n), 'YTickLabeLRotation', 45);
        %end

        % Get rid of X labels for all but bottom plot, set font size
        if n ~= chans
            set(ax(n),'XTickLabels',[]);
        else
            underfontsize = get(under_subplot, 'FontSize');
            set(ax(n).XAxis,'FontSize', underfontsize);
        end
    end

    % lastly, add plots to fig app data
    setappdata(panel, 'mp_axes', ax);
    for n=1:chans
        setappdata(ax(n), 'mp_axes', ax);
    end

    % resize
    multiplotresize(panel);

    % now focus under_panel, so subsequent subplots work on the figure
    setappdata(under_panel, 'panel', panel);
    axes(under_panel);
end
