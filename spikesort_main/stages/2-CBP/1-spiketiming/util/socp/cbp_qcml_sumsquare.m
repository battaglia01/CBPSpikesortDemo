function [c_coeffs u_coeffs v_coeffs optval] = cbp_qcml_sumsquare(params, varargin)

% Formulate problem and translate data to ECOS input format
qparams.dictc = params.dict(:, 1:3:end);
qparams.dictu = params.dict(:, 2:3:end);
qparams.dictv = params.dict(:, 3:3:end);
qparams.lambda = params.lambda;
qparams.data = params.data;
qparams.noise = 1/(sqrt(2)*params.noisesigma);
qparams.radii = diag(params.radii);
qparams.rctheta = diag(params.radii .* cos(params.theta));
qdims.m = size(qparams.dictc,1);
qdims.n = size(qparams.dictc,2);
[ecos_c, ecos_G, ecos_h, cones, ecos_A, ecos_b] = cbp2ecos_qcml_2norm(qparams, qdims);

% Solve!
x = ecos(ecos_c, ecos_G, ecos_h, cones, ecos_A, ecos_b);
optval =  x' * [ecos_c];

% Translate ECOS output into problem output
[c_coeffs, u_coeffs, v_coeffs] = ecos2cbp_qcml_2norm(x, qdims);


function [c, u, v] = ecos2cbp_qcml_2norm(x, dims)
c = x(1:dims.n);
u = x((1 + dims.n):2*dims.n);
v = x((1 + 2*dims.n):3*dims.n);


function [c, G, h, cones, A, b] = cbp2ecos_qcml_2norm(params, dims)
% PROB2SOCP: maps PARAMS into a struct of SOCP matrices
% Where input struct PARAMS has the following fields:
%   'dictu' has shape Matrix(m,n)
%   'noise' has shape Scalar()
%   'rctheta' has shape Matrix(n,n)
%   'radii' has shape Matrix(n,n)
%   'dictv' has shape Matrix(m,n)
%   'dictc' has shape Matrix(m,n)
%   'data' has shape Vector(m)
%   'lambda' has shape Vector(n)

p = 0; m = (4 + dims.m + 5*dims.n); n = (2 + 4*dims.n);
c = zeros(n,1);
h = zeros(m,1);
b = zeros(p,1);
Gi = []; Gj = []; Gv = [];
Ai = []; Aj = []; Av = [];

cones.l = 2*dims.n;
cones.q = [3; (1 + dims.m); 3*ones(dims.n,1)];
cones.s = [];

% stuffing the objective vector
c((2 + 3*dims.n):(2 + 3*dims.n)) = params.noise;
c(1:dims.n) = params.lambda;

% for the constraint _t2 + -1*radii*c <= 0
Gi = [Gi; (0:(-1 + dims.n))'];
Gj = [Gj; ((2 + 3*dims.n):(1 + 4*dims.n))'];
Gv = [Gv; 1*ones(dims.n,1)];
Gi = [Gi; mod(find(params.radii)-1,size(params.radii,1))];
Gj = [Gj; floor((find(params.radii)-1)/size(params.radii,1))];
Gv = [Gv; nonzeros(-params.radii)];

% for the constraint rctheta*c + -1*u <= 0
Gi = [Gi; dims.n + mod(find(params.rctheta)-1,size(params.rctheta,1))];
Gj = [Gj; floor((find(params.rctheta)-1)/size(params.rctheta,1))];
Gv = [Gv; nonzeros(params.rctheta)];
Gi = [Gi; (dims.n:(-1 + 2*dims.n))'];
Gj = [Gj; (dims.n:(-1 + 2*dims.n))'];
Gv = [Gv; -1*ones(dims.n,1)];

% for the SOC product constraint norm(1 + -1*_t1, 2.0*_t0) <= 1 + _t1
Gi = [Gi; (2 + 2*dims.n)];
Gj = [Gj; 3*dims.n];
Gv = [Gv; -2.0];
h((2 + 2*dims.n):3:(3 + 2*dims.n)) = 1;
Gi = [Gi; (1 + 2*dims.n)];
Gj = [Gj; (1 + 3*dims.n)];
Gv = [Gv; 1];
h((1 + 2*dims.n):3:(3 + 2*dims.n)) = 1;
Gi = [Gi; 2*dims.n];
Gj = [Gj; (1 + 3*dims.n)];
Gv = [Gv; -1];

% for the SOC constraint norm([data + -1*dictc*c + dictu*u + dictv*v]) <= _t0
h((5 + 2*dims.n):(4 + dims.m + 2*dims.n)) = params.data;
Gi = [Gi; (4 + 2*dims.n) + mod(find(params.dictc)-1,size(params.dictc,1))];
Gj = [Gj; floor((find(params.dictc)-1)/size(params.dictc,1))];
Gv = [Gv; nonzeros(params.dictc)];
Gi = [Gi; (4 + 2*dims.n) + mod(find(params.dictu)-1,size(params.dictu,1))];
Gj = [Gj; dims.n + floor((find(params.dictu)-1)/size(params.dictu,1))];
Gv = [Gv; nonzeros(params.dictu)];
Gi = [Gi; (4 + 2*dims.n) + mod(find(params.dictv)-1,size(params.dictv,1))];
Gj = [Gj; 2*dims.n + floor((find(params.dictv)-1)/size(params.dictv,1))];
Gv = [Gv; nonzeros(params.dictv)];
Gi = [Gi; (3 + 2*dims.n)];
Gj = [Gj; 3*dims.n];
Gv = [Gv; -1];

% for the SOC product constraint norm(u, v) <= _t2
Gi = [Gi; ((6 + dims.m + 2*dims.n):3:(5 + dims.m + 5*dims.n))'];
Gj = [Gj; (2*dims.n:(-1 + 3*dims.n))'];
Gv = [Gv; -1*ones(dims.n,1)];
Gi = [Gi; ((5 + dims.m + 2*dims.n):3:(4 + dims.m + 5*dims.n))'];
Gj = [Gj; (dims.n:(-1 + 2*dims.n))'];
Gv = [Gv; -1*ones(dims.n,1)];
Gi = [Gi; ((4 + dims.m + 2*dims.n):3:(3 + dims.m + 5*dims.n))'];
Gj = [Gj; ((2 + 3*dims.n):(1 + 4*dims.n))'];
Gv = [Gv; -1*ones(dims.n,1)];

% Convert from sparse triplet to column compressed format.
% Also convert from 0 indexed to 1 indexed.
A = sparse(Ai+1, Aj+1, Av, p, n);
G = sparse(Gi+1, Gj+1, Gv, m, n);