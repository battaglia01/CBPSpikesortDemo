% This creates a scrollable panel. It's two panels - an outer panel and an
% inner panel. The outer panel contains the inner panel and also the
% scrollbars.
%
% The user creates the inner panel first, and then
% passes that in as the first parameter to uiscrollpanel.
%
% The second parameter is the string "horiz", "vert", "both", or "none",
% indicating which scrollbars are present.
%
% The remaining parameters are passed to the outer panel as parameters to
% the outer panel.
function out = uiscrollpanel(inner_panel, scrollbars, max_horiz_offset, max_vert_offset, varargin)
%create scrollbars
    inner_panel_pos = get(inner_panel, "Position");
    
    orig_left = inner_panel_pos(1);
    orig_bottom = inner_panel_pos(2);
    
    outer_panel = uipanel(varargin{:}, ...
                    'Parent', get(inner_panel, 'Parent'));
    set(inner_panel, "Parent", outer_panel);
    
    if scrollbars == "horiz" || scrollbars == "both"
        % was min=0, max=1, value=0
        uihoriz = uicontrol('Units','normalized',...
                'Style','Slider',...
                'Position',[0,0,1,.025],...
                'Min',0,...
                'Max',1,...
                'Value',0,...
                'Parent', outer_panel);
        set(uihoriz, 'Callback', ...
            @(scr,event) scrollhoriz(uihoriz, inner_panel, orig_left, max_horiz_offset));
    end
    if scrollbars == "vert" || scrollbars == "both"
        if scrollbars == "both"
            vert_pos = [.98,.03,.02,.97];
        elseif scrollbars == "vert"
            vert_pos = [.98,0,.02,1];
        end
        % was min=0, max=1, value=1
        uivert = uicontrol('Units','normalized',...
                'Style','Slider',...
                'Position',vert_pos,...
                'Min',0,...
                'Max',1,...
                'Value',1,...
                'visible','on',...
                'Parent', outer_panel);
        set(uivert, 'Callback', ...
            @(scr,event) scrollvert(uivert, inner_panel, orig_bottom, max_vert_offset));
    end
    
    out = outer_panel;
end

% -----------------
function scrollhoriz(scrollbar, inner_panel, orig_left, max_horiz_offset)
   pos = get(inner_panel,'Position');
   val = get(scrollbar,'value');

   pos(1) = orig_left - max_horiz_offset*val;

   set(inner_panel,'Position', pos);
end

% -----------------
function scrollvert(scrollbar, inner_panel, orig_bottom, max_vert_offset)
   pos = get(inner_panel,'Position');
   val = get(scrollbar,'value');

   %%after all is said and done, the above scrolls it correctly
   pos(2) = orig_bottom + max_vert_offset*(1-val);

   set(inner_panel,'Position', pos);
end
