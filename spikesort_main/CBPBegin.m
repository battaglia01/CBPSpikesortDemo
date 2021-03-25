%===============================================================
% This is the main CBP script.
% You can send in the input parameters that you want by setting the
% "params" object beforehand.
%
% Usage: CBPBegin

function CBPBegin
% set up globals (even in base workspace) and path
global CBPdata params CBPInternals;

evalin('base','global CBPdata params');
[curpath, ~, ~] = fileparts(mfilename('fullpath') + ".m");
addpath(genpath(curpath));

% If there's an existing session, ask before overwriting and beginning anew
answer = questdlg("Welcome to CBP. " + ...
                  "If you have any CBP data already loaded into the " + ...
                  "workspace, this will clear it and begin a new " + ...
                  "session. Are you sure you want to clear existing "+ ...
                  "data and begin?", ...
                  "New Session?", "Yes", "No", "No");
if answer == "Yes"
    CBPInternals.skip_close_confirmation = true;
    CBPReset;   % this deletes CBPInternals, so don't need to reset
else
    return;
end

% Add all subdirectories of this one to the path, and init everything
BasicSetup;

% Open import file dialog, only proceed if the user doesn't choose cancel
result = ImportFileDialog;
if ~result % returns true if user didn't cancel
    return;
end
clear result;

% lastly, replot up to the last computed stage and exist, or call RawData
% if it doesn't exist
if ~isempty(CBPdata.last_stage_name)
    ReplotTabsUpToStage(CBPdata.last_stage_name)
else
    CBPNext;    % basically just calls RawData
end
