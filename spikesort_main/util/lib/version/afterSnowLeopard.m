<<<<<<< HEAD:spikesort_main/util/lib/version/afterSnowLeopard.m
function bool = afterSnowLeopard()
if ~ismac(), bool = false; return; end

[~,systemrelease] = system('uname -r');
systemrelease = sscanf(systemrelease, '%d.%d.%d.');
=======
function bool = afterSnowLeopard()
if ~ismac(), bool = false; return; end

[~,systemrelease] = system('uname -r');
systemrelease = sscanf(systemrelease, '%d.%d.%d.');
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc:spikesort_main/util/lib/version/afterSnowLeopard.m
bool = systemrelease(1) > 10;