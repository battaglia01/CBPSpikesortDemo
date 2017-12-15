%% -----------------------------------------------------------------------------------
% CBP step 0: iteration setup
%
% This is a simple "pre-round" to set up the next iteration of CBP.
% To do this, we simply copy the final waveforms from the last round
% to the initial waveforms from the next round.

function CBPIterate
global params dataobj;

fprintf('***CBP step 0: Iterating CBP...\n');
fprintf('***Seeding new initial waveforms with previous final waveforms...\n');

%set up CBPinfo, init_waveforms
if dataobj.CBPinfo.first_pass
    dataobj.CBPinfo.init_waveforms = dataobj.clustering.init_waveforms;
else
    dataobj.CBPinfo.init_waveforms = dataobj.CBPinfo.final_waveforms;
    dataobj.CBPinfo.final_waveforms = {};
end

fprintf('***Completed iteration setup.\n\n');
CBPNext('CBPSetupStage')
