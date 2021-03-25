function RescaleAxes(zoomlevel, xpos)
global CBPdata params CBPInternals;
    if ~exist('params') || ~exist('CBPdata') || ...
            ~isfield(CBPdata,'raw_data') || ~isfield(CBPdata.raw_data,'dt')
        fprintf('ERROR: must load raw data before changing scroll times!\n\n');
    else
        %%@startind = round(starttime./CBPdata.raw_data.dt)+1;
        %%@endind = round(endtime./CBPdata.raw_data.dt)+1;
        params.plotting.zoomlevel = zoomlevel;
        params.plotting.xpos = xpos;

        UpdateScrollAxes;
    end
end
