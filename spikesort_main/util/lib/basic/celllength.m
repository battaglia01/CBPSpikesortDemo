<<<<<<< HEAD:spikesort_main/util/lib/basic/celllength.m
function s = celllength(S)

s = zeros(size(S));
1;
for i=1:numel(S)
    if (numel(S{i}) == 0)
        s(i) = 0;
    else
        s(i) = size(S{i},1);
    end
end
=======
function s = celllength(S)

s = zeros(size(S));
1;
for i=1:numel(S)
    if (numel(S{i}) == 0)
        s(i) = 0;
    else
        s(i) = size(S{i},1);
    end
end
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc:spikesort_main/util/lib/basic/celllength.m
    