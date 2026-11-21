function Network = make_network(Liabilities, ExternalDebt, Cash, RiskyAssets)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make_network.m                                                              %
% Time-0 interlocking balance sheets of a network (Section 3, Equation 3)     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Collects the balance-sheet primitives in a struct and checks Assumption 1
% (non-negative primitives) and solvency at time 0
% Input(s):
% -- Liabilities: n x n, L(i,j) = amount borrowed by node i from node j
%    (L' is the matrix of internal loans: row j of L' = loans made by j)
% -- ExternalDebt: n x 1, delta
% -- Cash: n x 1, eta
% -- RiskyAssets: n x 1, time-0 value of each node's risky assets, Theta * 1
% Output(s): struct Network with the four inputs as fields and
% -- .Size: balance-sheet size, varsigma = eta + Theta * 1 + L' * 1
% -- .Equity: time-0 equity, gamma = varsigma - delta - L * 1
% formula: varsigma = gamma + delta + L * 1 = eta + Theta * 1 + L' * 1 (Eq. 3)

Primitives = [Liabilities(:); ExternalDebt; Cash; RiskyAssets]; % all entries
% Counterfactual systems are computed by the accounting equation, so allow
% rounding errors (e.g., -1e-14) in entries that are 0 in exact arithmetic
Tolerance = 1e-9 * max(1, max(abs(Primitives)));
if any(Primitives < -Tolerance)
    error('Balance-sheet primitives must be non-negative (Assumption 1).');
end

Network.Liabilities = Liabilities;    % L
Network.ExternalDebt = ExternalDebt;  % delta
Network.Cash = Cash;                  % eta
Network.RiskyAssets = RiskyAssets;    % Theta * 1

InternalLoans = sum(Liabilities, 1)'; % L' * 1, lent by each node
InternalDebt = sum(Liabilities, 2);   % L * 1, borrowed by each node
Network.Size = Cash + RiskyAssets + InternalLoans;              % varsigma
Network.Equity = Network.Size - ExternalDebt - InternalDebt;   % gamma
if any(Network.Equity < -Tolerance)
    error('Some nodes are insolvent at time 0.');
end
end
