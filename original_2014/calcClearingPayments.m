function clearvar = calcClearingPayments(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn)
% clearvar = calcClearingPayments(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn)
%  Function for calcuating the clearing payment vector and sensitivity info 
% using the method of Proposition 1 of Liu&Staum.
%
% Inputs:
%   LiabMat      - N-by-N interbank liability matrix at time 0
%   ExtDebt      - N-by-1 vector of external debt 
%   Cash         - N-by-1 vector of cash holding
%   RiskyHolding - N-by-1 vector of risky asset
%   RiskyRtn     - N-by-1 vector of risky asset return
%
% Output:
%   clearvar - structure of clearing payment and sensitivity info

%% Check solvency at time 0
NumNodes = size(LiabMat,1);     % number of nodes in the system

Equity = Cash + RiskyHolding + sum(LiabMat,1)' - ExtDebt - sum(LiabMat,2);
if(any(Equity<0))
    error('Some nodes are insolvent at time 0!');
end

%% Set up algorithm inputs
e = Cash + RiskyHolding .* (1 + RiskyRtn);    % external assets
if(any(e<0))
    error('Negative external asset at time 1!');
end

p_bar = ExtDebt + sum(LiabMat,2); % total debt (internal and external)

% fractions of the outflow from node i that goes to node j
Pi = bsxfun(@times, 1./p_bar, LiabMat); % same as diag(p_bar)^(-1)*LoanMat'
Pi(~isfinite(Pi)) = 0;  % if p_bar_i = 0 then the ith row of Pi is set to zero

% fractions of the nodes' outflows that go to external creditors (sink node)
Pi0 = bsxfun(@times, 1./p_bar, ExtDebt); % same as diag(p_bar)^(-1)*ExtDebt'
Pi0(~isfinite(Pi0)) = 0; % if p_bar_i = 0 then the ith element of Pi0 is set to zero

%% Solve for p
% Initiliaze
p_s = nan(NumNodes,1);      % place holder for clearing payment vector
flag_D = false(NumNodes,1); % defaulting nodes (initially none)
flag_N = ~flag_D;           % non-defaulting nodes (initially all nodes)

p_s(flag_N) = p_bar(flag_N); % clearing payment equals to total debt
flag_wrong = flag_N & (p_bar > e + Pi'*p_s); % nodes with wrong flags

% a node's flag is wrong if its total asset is less than total liability
% but has a non-defaulting flag
while( sum(flag_wrong)>0 )  % still have nodes with wrong flags
    flag_D = flag_D | flag_wrong;   % union(flag_D, flag_wrong)
    flag_N = ~flag_D;          
    
    p_s(flag_N) = p_bar(flag_N);    % clearing payments of non-defaulting nodes
    
    Nd = sum(flag_D);   % number of misclassified nodes 
    p_s(flag_D) = (eye(Nd)-Pi(flag_D, flag_D)')\(e(flag_D)+Pi(flag_N, flag_D)'*p_bar(flag_N));
    flag_wrong = flag_N & (p_bar > e + Pi'*p_s);
end

%% Sensitivity analysis
v_s = e + Pi'*p_s - p_s;    % Time-1 equity
v_s = max(v_s,0);

f_s = p_s./p_bar; % payment fractions
f_s(~isfinite(f_s)) = 1;

eps = 1e-8;
flag_r = 1-f_s > eps;   % red nodes
flag_g = v_s > eps;     % green nodes
flag_y = (f_s >= 1-eps) & (v_s <= eps); % yellow nodes (borderline nodes)

flag_D = flag_r;    % defaulting nodes
flag_N = ~flag_D;   % non-defaulting nodes (green and yellow)

left_deriv = zeros(NumNodes,NumNodes);
left_deriv(~flag_g,~flag_g) = inv(eye(sum(~flag_g))-Pi(~flag_g, ~flag_g)');

right_deriv = zeros(NumNodes,NumNodes);
right_deriv(flag_D,flag_D) = inv(eye(sum(flag_D))-Pi(flag_D, flag_D)');


%% Gathering outputs
clearvar.ClearingP = p_s;           % clearing payment vector
clearvar.TotalDebt = p_bar;         % total debts

clearvar.Equity = v_s;              % Time-1 equity
clearvar.PayFrac = f_s;             % payment fractions

clearvar.RedSet = flag_r;           % Set of red nodes
clearvar.GreenSet = flag_g;         % Set of green nodes
clearvar.YellowSet = flag_y;        % Set of yellow nodes

clearvar.DefaultSet = flag_r;       % Set of defaulting nodes
clearvar.NonDefaultSet = flag_N;    % Set of non-defaulting nodes

% Del-p-Del-e: sensitivity of clearing payments to external assets
clearvar.LeftDeriv = left_deriv;    
clearvar.RightDeriv = right_deriv;

zeta = right_deriv' * Pi0;
clearvar.Grad_e = - zeta;

% fraction of outflows relative to different debts
clearvar.Pi = Pi;
clearvar.Pi0 = Pi0;
end

