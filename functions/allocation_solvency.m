function Allocation = allocation_solvency(Network, RiskyProfit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% allocation_solvency.m                                                       %
% Solvency method (Section 4.5, Online Supplement C.3): the intermediation    %
% scheme with borrower responsibility, L_ij(lambda) = lambda_i L_ij, and the  %
% Aumann-Shapley value (closed form; the cost function is homogeneous)        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- Network: struct from make_network.m
% -- RiskyProfit: n x 1, profit on the risky assets, Theta * (a - 1)
% Output(s):
% -- Allocation: n x 1, cost allocated to the nodes in this scenario
% formula: phi_i = -zeta_i (gamma_i + Theta_i. (a - 1)), i.e. minus the
%   marginal price of wealth times equity plus profit on external assets;
%   zero for green nodes (zeta_i = 0)

Clearing = clearing_payments(Network, RiskyProfit);   % zeta of the real system
NetContribution = Network.Equity + RiskyProfit;      % gamma_i + Theta_i. (a - 1)
Allocation = -Clearing.Zeta .* NetContribution;
end
