function Clearing = clearing_payments(Network, RiskyProfit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clearing_payments.m                                                         %
% Clearing payments of the Eisenberg-Noe network model (Section 3.1) and the  %
% sensitivities of payments and cost to income (Section 3.2)                  %
% Notation of the paper: L (liabilities), delta (external debt), e (income),  %
% p_bar (total debt), Pi, Pi0 (outflow fractions), p*, f*, v*, zeta           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clearing payment vector by the algorithm of Proposition 1, colors of the
% nodes (definition in Section 3.2), one-sided derivatives of payments to
% income (Corollary 1) and marginal prices of wealth zeta (Equations 10, 13)
% Input(s):
% -- Network: struct with the time-0 balance sheets (see make_network.m)
%    .Liabilities: n x n, L(i,j) = amount borrowed by node i from node j
%    .ExternalDebt: n x 1, delta
%    .Cash: n x 1, eta
%    .RiskyAssets: n x 1, time-0 value of the risky assets, Theta * 1
% -- RiskyProfit: n x 1, profit on the risky assets, Theta * (a - 1)
% Output(s): struct Clearing with
% -- .Income: e = eta + Theta * a (Equation 4)
% -- .TotalDebt: p_bar = delta + L * 1
% -- .Pi, .Pi0: fractions of the outflow of node i that go to node j and to
%    the external creditors (sink node)
% -- .Payments: clearing payments p*
% -- .PayFraction: payment fractions f* = p* / p_bar (1 if p_bar = 0)
% -- .Equity: time-1 equity v* = e + Pi' * p* - p*
% -- .Red, .Green, .Borderline: logical n x 1, colors of the nodes
% -- .LeftDeriv, .RightDeriv: n x n left and right derivatives of p* to e
% -- .Zeta: n x 1, marginal prices of wealth (from right derivatives)
% formula: zeta = (right derivative of p* to e)' * Pi0 (Equation 10)

NumNodes = size(Network.Liabilities, 1); % number of nodes n
Liabilities = Network.Liabilities;       % L

% ===== Time-0 and time-1 balance sheets
InternalLoans = sum(Liabilities, 1)';    % L' * 1, lent by each node
InternalDebt = sum(Liabilities, 2);      % L * 1, borrowed by each node
Equity0 = Network.Cash + Network.RiskyAssets + InternalLoans ...
    - Network.ExternalDebt - InternalDebt; % time-0 equity gamma
if any(Equity0 < 0)
    error('Some nodes are insolvent at time 0.');
end

Income = Network.Cash + Network.RiskyAssets + RiskyProfit; % e = eta + Theta * a
if any(Income < 0)
    error('Negative external asset value at time 1.');
end

TotalDebt = Network.ExternalDebt + InternalDebt; % p_bar = delta + L * 1

% Outflow fractions Pi(i,j) = L(i,j) / p_bar(i), Pi0(i) = delta(i) / p_bar(i);
% a node without debt (p_bar(i) = 0) gets a row of zeros
Pi = zeros(NumNodes, NumNodes);   % fractions of outflows to other nodes
Pi0 = zeros(NumNodes, 1);         % fractions of outflows to external creditors
HasDebt = TotalDebt > 0;          % nodes with p_bar(i) > 0
Pi(HasDebt, :) = Liabilities(HasDebt, :) ./ TotalDebt(HasDebt);
Pi0(HasDebt) = Network.ExternalDebt(HasDebt) ./ TotalDebt(HasDebt);

% ===== Clearing payments (Proposition 1)
%-- Step 1: no node defaults; every node pays its total debt
Payments = TotalDebt;                 % p^k
Defaulting = false(NumNodes, 1);      % D_k, nodes identified as defaulting
Inflow = Income + Pi' * Payments;     % e + Pi' * p^k
NewDefaults = ~Defaulting & (TotalDebt > Inflow); % D_k', step 3

while any(NewDefaults)
    %-- Step 4: add the new defaulting nodes
    Defaulting = Defaulting | NewDefaults;
    NonDefaulting = ~Defaulting;      % N_k
    NumDefaulting = sum(Defaulting);  % |D_k|

    %-- Step 2: non-defaulting nodes pay in full; defaulting nodes pay
    % their inflow (Equation 8, the Markov-chain formula)
    Payments(NonDefaulting) = TotalDebt(NonDefaulting);
    PiDD = Pi(Defaulting, Defaulting);       % Pi among defaulting nodes
    PiND = Pi(NonDefaulting, Defaulting);    % Pi from non-defaulting to defaulting
    InflowFromOutside = Income(Defaulting) + PiND' * TotalDebt(NonDefaulting);
    Payments(Defaulting) = (eye(NumDefaulting) - PiDD') \ InflowFromOutside;

    %-- Step 3: nodes that cannot pay in full given these payments
    Inflow = Income + Pi' * Payments;
    NewDefaults = ~Defaulting & (TotalDebt > Inflow);
end

% ===== Colors of the nodes (definition in Section 3.2)
Equity1 = max(Income + Pi' * Payments - Payments, 0); % time-1 equity v*
PayFraction = ones(NumNodes, 1);                       % f* = 1 if p_bar = 0
PayFraction(HasDebt) = Payments(HasDebt) ./ TotalDebt(HasDebt);

Tolerance = 1e-8;  % numerical tolerance for comparisons with 0 and 1
Red = 1 - PayFraction > Tolerance;                       % f* < 1
Green = Equity1 > Tolerance;                             % v* > 0
Borderline = (PayFraction >= 1 - Tolerance) & (Equity1 <= Tolerance);

% ===== Sensitivities of payments to income (Corollary 1)
% Right derivatives: (I - Pi_RR')^(-1) on the red nodes, zero elsewhere.
% Left derivatives: the same with the red nodes replaced by the non-green
% (red and borderline) nodes.
NotGreen = ~Green;
LeftDeriv = zeros(NumNodes, NumNodes);
LeftDeriv(NotGreen, NotGreen) = inv(eye(sum(NotGreen)) - Pi(NotGreen, NotGreen)');
RightDeriv = zeros(NumNodes, NumNodes);
RightDeriv(Red, Red) = inv(eye(sum(Red)) - Pi(Red, Red)');
% inv() as in the original code (the matrices are small); the same results
% as the backslash operator up to rounding

% Marginal prices of wealth (Equation 10): zeta = -(gradient of the loss
% with respect to income); zeta = 0 for green nodes (Equation 13)
Zeta = RightDeriv' * Pi0;

% ===== Outputs
Clearing.Income = Income;            % e
Clearing.TotalDebt = TotalDebt;      % p_bar
Clearing.Pi = Pi;                    % Pi
Clearing.Pi0 = Pi0;                  % Pi0
Clearing.Payments = Payments;        % p*
Clearing.PayFraction = PayFraction;  % f*
Clearing.Equity = Equity1;           % v*
Clearing.Red = Red;                  % red nodes R
Clearing.Green = Green;              % green nodes G
Clearing.Borderline = Borderline;    % borderline nodes
Clearing.LeftDeriv = LeftDeriv;      % left derivatives of p* to e
Clearing.RightDeriv = RightDeriv;    % right derivatives of p* to e
Clearing.Zeta = Zeta;                % zeta
end
