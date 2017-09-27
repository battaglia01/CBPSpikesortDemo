<<<<<<< HEAD:spikesort_main/util/lib/cbp/polar_1D/polar_1D_adjust_wfsize.m
function W = polar_1D_adjust_wfsize(W0,snipratio,snipthres,maxlen)
% Snip (or augment) the waveforms on either side to adapt the length

W = W0;

for i = 1 : length(W)
    W{i} = alignPeak(W{i},size(W{i},1),'centroid');
end

for i=1:length(W)     
    peakval = max(max(abs(W{i})));
    lhs = find(max(abs(W{i}),[],2) > snipthres*peakval,1,'first');
    rhs = find(max(abs(W{i}),[],2) > snipthres*peakval,1,'last');
    cutoff = min(lhs,size(W{i},1)-rhs);
    snipbuff = round(max(3,snipratio*size(W{i},1)));
    if (2*snipbuff+size(W{i},1)-2*cutoff <= maxlen)
        W{i} = [zeros(snipbuff,size(W{i},2)); W{i}(cutoff+1:end-cutoff,:);zeros(snipbuff,size(W{i},2))];          
    end    
end    

% Make sure lengths are odd
for i=1:length(W)
    if (mod(size(W{i},1),2) == 0)
        W{i} = [W{i};zeros(1,size(W{i},2))];
    end
=======
function W = polar_1D_adjust_wfsize(W0,snipratio,snipthres,maxlen)
% Snip (or augment) the waveforms on either side to adapt the length

W = W0;

for i = 1 : length(W)
    W{i} = alignPeak(W{i},size(W{i},1),'centroid');
end

for i=1:length(W)     
    peakval = max(max(abs(W{i})));
    lhs = find(max(abs(W{i}),[],2) > snipthres*peakval,1,'first');
    rhs = find(max(abs(W{i}),[],2) > snipthres*peakval,1,'last');
    cutoff = min(lhs,size(W{i},1)-rhs);
    snipbuff = round(max(3,snipratio*size(W{i},1)));
    if (2*snipbuff+size(W{i},1)-2*cutoff <= maxlen)
        W{i} = [zeros(snipbuff,size(W{i},2)); W{i}(cutoff+1:end-cutoff,:);zeros(snipbuff,size(W{i},2))];          
    end    
end    

% Make sure lengths are odd
for i=1:length(W)
    if (mod(size(W{i},1),2) == 0)
        W{i} = [W{i};zeros(1,size(W{i},2))];
    end
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc:spikesort_main/util/lib/cbp/polar_1D/polar_1D_adjust_wfsize.m
end