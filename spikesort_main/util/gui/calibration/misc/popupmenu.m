% Creates a popup menu button.
%
% The arguments to this are as follows:
%   - "fig" - the parent figure for both the menu and the button
%   - "ButtonArgs" - the arguments for the button
%   - "MenuArgs" - the arguments for the menu
%   - "Entries" - a cell array of cell arrays, each containing all of
%                 the parameters for the child menu entries.
%                 Example: {'Label', 'Menu Entry', 'Callback', @entry1}s
%   and their arguments
% The function can 
%
% function outbutton = popupmenu(fig, entries, varargin)
function menubutton = popupmenu(parent, varargin)
    p = inputParser;
    p.addParameter("ButtonArgs", {});
    p.addParameter("MenuArgs", {});
    p.addParameter("Entries", {});
    p.parse(varargin{:});
    
    fig = ancestor(parent, 'figure');
    
    % create button and context menu
    cm = uicontextmenu(fig, p.Results.MenuArgs{:});
    
    % create menu button, set the callback to popup our cm
    menubutton = uicontrol(parent, 'Style', 'pushbutton', ...
                                p.Results.ButtonArgs{:});
    set(menubutton, 'Callback', @(varargin) dopopup(fig, menubutton, cm));
    
    for n=1:length(p.Results.Entries)
        cur_menu = uimenu('Parent', cm, p.Results.Entries{n}{:});
    end 
end

function dopopup(fig, menubutton, cm)
    buttonpos = getpixelposition(menubutton, true);
    figurepos = get(fig, 'Position');
    newpos = [buttonpos(1) buttonpos(2)+buttonpos(4)];
    
    set(cm, 'Position', newpos, 'Visible', 'on');
end