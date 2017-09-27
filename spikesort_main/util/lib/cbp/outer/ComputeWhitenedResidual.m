<<<<<<< HEAD:spikesort_main/util/lib/cbp/outer/ComputeWhitenedResidual.m
function residual = ComputeWhitenedResidual(data, reconstructed_data, ...
                                            whitening_mtx_fn)

    data_vec = vectorize_cell(data);
    reconstructed_data_vec = vectorize_cell(reconstructed_data);
    residual = WhitenVectorBlocks(data_vec - reconstructed_data_vec, ...
                                  celllength(data), size(data{1}, 2), ...
                                  whitening_mtx_fn);


end
=======
function residual = ComputeWhitenedResidual(data, reconstructed_data, ...
                                            whitening_mtx_fn)

    data_vec = vectorize_cell(data);
    reconstructed_data_vec = vectorize_cell(reconstructed_data);
    residual = WhitenVectorBlocks(data_vec - reconstructed_data_vec, ...
                                  celllength(data), size(data{1}, 2), ...
                                  whitening_mtx_fn);


end
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc:spikesort_main/util/lib/cbp/outer/ComputeWhitenedResidual.m
