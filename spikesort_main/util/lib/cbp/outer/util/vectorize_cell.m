<<<<<<< HEAD:spikesort_main/util/lib/cbp/outer/util/vectorize_cell.m
function xvec = vectorize_cell(X)

xvec = zeros(sum(cellnumel(X)),1);
offset = 0;
for i=1:length(X)
    xvec(offset+1:offset+numel(X{i})) = X{i}(:);
    offset = offset + numel(X{i});
=======
function xvec = vectorize_cell(X)

xvec = zeros(sum(cellnumel(X)),1);
offset = 0;
for i=1:length(X)
    xvec(offset+1:offset+numel(X{i})) = X{i}(:);
    offset = offset + numel(X{i});
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc:spikesort_main/util/lib/cbp/outer/util/vectorize_cell.m
end