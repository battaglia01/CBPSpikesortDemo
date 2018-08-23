function ChangeScroll(starttime, endtime)
global dataobj params cbpglobals;
    if ~exist('params') || ~exist('dataobj') || ...
            ~isfield(dataobj,'rawdata') || ~isfield(dataobj.rawdata,'dt')
        fprintf('ERROR: must load raw data before changing scroll times!\n\n');
    else
        %%@startind = round(starttime./dataobj.rawdata.dt)+1;
        %%@endind = round(endtime./dataobj.rawdata.dt)+1;
        params.plotting.data_plot_times = [starttime endtime];
        
        UpdateScrollAxes;
    end
end