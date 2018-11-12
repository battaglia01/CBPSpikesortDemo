%===============================================================
% This is the main CBP script.
% You can send in the input parameters that you want by setting the
% "params" object beforehand.
% To set the filename you want, put that in params.general.filename.

global params dataobj;
eval('global params dataobj','base');
%%Establish path
addpath(genpath(pwd));

%%Begin script. The stages proceed linearly from here
InitAllStages;