<<<<<<< HEAD:spikesort_main/util/lib/cbp/outer/solve_basis_grad_step.m
function [success new_basis reconstructed_data objective_value] = ...
    solve_basis_grad_step(data, CoeffMat, current_basis, pars, outer_pars)

% Updates the basis functions by pushing them in the direction of the
% gradient of the L2 norm of the residual (which is the back projected
% residual). Do a line search in the direction of the gradient to determine
% the step size.

% Arguments:
% data : cell array of data samples (vecorized to be b in the above equation)
% CoeffMat : spike coefficient matrix (depends on interpolator) : should be sparse!
% current_basis : current estimate of basis
% noise_sigma (optional) : std. dev. of noise.

% Returns:
% success : whether or not update was successful
% new_basis : new estimate of basis
% reconstructed_data : reconstruction of the data w.r.t. this basis
%                      (same size as data)
% objective_value : squared L2 norm of the residual

%if (~exist('noise_sigma', 'var'))
%    noise_sigma = 1;
%end

%num_basis = length(current_basis);
%basis_lens = cellnumel(current_basis);
%dim = sum(basis_lens);
% Sparsify matrix if not already done.
CoeffMat = sparse(CoeffMat);

current_basis_vector = vectorize_cell(current_basis);
data_vector = vectorize_cell(data);
residual = data_vector - CoeffMat * current_basis_vector;
    
whitening_mtx_fn = getWhiteningMtxFn(pars);
whitened_residual = WhitenVectorBlocks(residual, ...
                                       celllength(data), ...
                                       size(data{1}, 2), ...
                                       whitening_mtx_fn);
old_objective_value = (1 / (sqrt(2) * pars.noise_sigma) * norm(whitened_residual)).^2;
if (pars.debug_mode)
    fprintf('Old l2 term: %0.3f\n', old_objective_value);
end
% Compute the gradient. DO NOT normalize it.
grad = CoeffMat' * ...
       WhitenVectorBlocks(whitened_residual, ...
                          celllength(data), ...
                          size(data{1}, 2), ...
                          whitening_mtx_fn);
%grad = grad ./ norm(grad);
success = sum(isnan(grad) | abs(grad) == Inf) == 0;

% Set step_size to the optimum step size (closed form solution)

Cg = WhitenVectorBlocks(CoeffMat * grad, ...
                        celllength(data), ...
                        size(data{1}, 2), ...
                        whitening_mtx_fn);
step_size = 1; %dot(whitened_residual, Cg) / sum(Cg(:).^2);                         

% Update the basis
basis_vec = current_basis_vector + step_size * grad;       
reconstructed_data_vector = CoeffMat * basis_vec;
reconstructed_data = vec2cell(reconstructed_data_vector, ...
                              celllength(data), size(data{1}, 2));
                          
basis_vec = double(basis_vec);

new_whitened_residual = WhitenVectorBlocks( ...
    data_vector - CoeffMat * basis_vec, ...
    celllength(data), size(data{1}, 2), whitening_mtx_fn);

objective_value = (1 / (sqrt(2) * pars.noise_sigma) * norm(new_whitened_residual)).^2;
if (pars.debug_mode)
    fprintf('New l2 term: %0.3f\n', objective_value);
end

if 0 %(objective_value > old_objective_value)
    error('There was supposed to be a decrease in the l2 term!');
    success = 0;
end

% Put it back into cell format
new_basis = vec2cell(basis_vec, celllength(current_basis), ...
=======
function [success new_basis reconstructed_data objective_value] = ...
    solve_basis_grad_step(data, CoeffMat, current_basis, pars, outer_pars)

% Updates the basis functions by pushing them in the direction of the
% gradient of the L2 norm of the residual (which is the back projected
% residual). Do a line search in the direction of the gradient to determine
% the step size.

% Arguments:
% data : cell array of data samples (vecorized to be b in the above equation)
% CoeffMat : spike coefficient matrix (depends on interpolator) : should be sparse!
% current_basis : current estimate of basis
% noise_sigma (optional) : std. dev. of noise.

% Returns:
% success : whether or not update was successful
% new_basis : new estimate of basis
% reconstructed_data : reconstruction of the data w.r.t. this basis
%                      (same size as data)
% objective_value : squared L2 norm of the residual

%if (~exist('noise_sigma', 'var'))
%    noise_sigma = 1;
%end

%num_basis = length(current_basis);
%basis_lens = cellnumel(current_basis);
%dim = sum(basis_lens);
% Sparsify matrix if not already done.
CoeffMat = sparse(CoeffMat);

current_basis_vector = vectorize_cell(current_basis);
data_vector = vectorize_cell(data);
residual = data_vector - CoeffMat * current_basis_vector;
    
whitening_mtx_fn = getWhiteningMtxFn(pars);
whitened_residual = WhitenVectorBlocks(residual, ...
                                       celllength(data), ...
                                       size(data{1}, 2), ...
                                       whitening_mtx_fn);
old_objective_value = (1 / (sqrt(2) * pars.noise_sigma) * norm(whitened_residual)).^2;
if (pars.debug_mode)
    fprintf('Old l2 term: %0.3f\n', old_objective_value);
end
% Compute the gradient. DO NOT normalize it.
grad = CoeffMat' * ...
       WhitenVectorBlocks(whitened_residual, ...
                          celllength(data), ...
                          size(data{1}, 2), ...
                          whitening_mtx_fn);
%grad = grad ./ norm(grad);
success = sum(isnan(grad) | abs(grad) == Inf) == 0;

% Set step_size to the optimum step size (closed form solution)

Cg = WhitenVectorBlocks(CoeffMat * grad, ...
                        celllength(data), ...
                        size(data{1}, 2), ...
                        whitening_mtx_fn);
step_size = 1; %dot(whitened_residual, Cg) / sum(Cg(:).^2);                         

% Update the basis
basis_vec = current_basis_vector + step_size * grad;       
reconstructed_data_vector = CoeffMat * basis_vec;
reconstructed_data = vec2cell(reconstructed_data_vector, ...
                              celllength(data), size(data{1}, 2));
                          
basis_vec = double(basis_vec);

new_whitened_residual = WhitenVectorBlocks( ...
    data_vector - CoeffMat * basis_vec, ...
    celllength(data), size(data{1}, 2), whitening_mtx_fn);

objective_value = (1 / (sqrt(2) * pars.noise_sigma) * norm(new_whitened_residual)).^2;
if (pars.debug_mode)
    fprintf('New l2 term: %0.3f\n', objective_value);
end

if 0 %(objective_value > old_objective_value)
    error('There was supposed to be a decrease in the l2 term!');
    success = 0;
end

% Put it back into cell format
new_basis = vec2cell(basis_vec, celllength(current_basis), ...
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc:spikesort_main/util/lib/cbp/outer/solve_basis_grad_step.m
                     size(current_basis{1}, 2));