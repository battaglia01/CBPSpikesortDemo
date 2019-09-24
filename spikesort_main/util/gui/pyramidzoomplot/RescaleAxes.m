function RescaleAxes(zoomlevel, xpos)
global CBPdata params CBPInternals;
    if ~exist('params') || ~exist('CBPdata') || ...
            ~isfield(CBPdata,'rawdata') || ~isfield(CBPdata.rawdata,'dt')
        fprintf('ERROR: must load raw data before changing scroll times!\n\n');
    else
        %%@startind = round(starttime./CBPdata.rawdata.dt)+1;
        %%@endind = round(endtime./CBPdata.rawdata.dt)+1;
        params.plotting.zoomlevel = zoomlevel;
        params.plotting.xpos = xpos;

        UpdateScrollAxes;
    end
end
