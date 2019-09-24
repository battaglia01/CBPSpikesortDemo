% Creates the Params figure. Called by GetParamsFigure.
% If you want to create the params figure in the program,
% you usually want to call GetParamsFigure, not this.

function h = CreateParamsFigure
    global CBPdata params CBPInternals;

    %Set look and feel. Taken from
    %http://undocumentedmatlab.com/blog/modifying-matlab-look-and-feel/
    javax.swing.UIManager.setLookAndFeel('javax.swing.plaf.metal.MetalLookAndFeel');

    %If it doesn't already exist, create it
    h = figure(params.plotting.params_figure);
    h.NumberTitle = 'off';
    h.Name = 'Verify Parameters';
    set(gcf, 'ToolBar', 'none');

    % Set up tab group
    tg = uitabgroup(h, 'TabLocation', 'left', ...
                       'Tag', 'params_tg', ...
                       'Units', 'normalized', ...
                       'Position', [0 0.075 1 0.925]);

    % Add one for each field
    f = fieldnames(params);
    for n=1:length(f)
        name = f(n);
        name = name{1};
        t = uitab(tg,'Title',name,'Tag',['params_t_' name]);
        p = CreateParamsPanel(name, t);
    end

    %Create params status bar and disable until something is changed
    sb = GetParamsStatus;

    % Restore original look and feel
    javax.swing.UIManager.setLookAndFeel(CBPInternals.originalLnF);
end
