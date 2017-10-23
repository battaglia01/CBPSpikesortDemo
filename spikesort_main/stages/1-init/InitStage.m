function InitStage(p)
global params dataobj nextstage;
% Run the setup function, which sets paths and prints warnings or errors if
% there are issues detected (for example, mex/C files that need to be compiled
% for your system).

fprintf('***Running initial setup...\n');

clear nextstage;

SpikesortDemoSetup;
FillInDefaultParameters;

fprintf('***Done initialization.\n\n');
CBPNext('RawDataStage');