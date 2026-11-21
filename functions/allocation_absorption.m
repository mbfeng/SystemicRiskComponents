function Allocation = allocation_absorption(Network, RiskyProfit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% allocation_absorption.m                                                     %
% Absorption method (Section 4.6, Online Supplement C.4): the intermediation  %
% scheme with lender responsibility, L_ij(lambda) = lambda_j L_ij, and the    %
% Aumann-Shapley value (closed form; the cost function is homogeneous)        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- Network: struct from make_network.m
% -- RiskyProfit: n x 1, profit on the risky assets, Theta * (a - 1)
% Output(s):
% -- Allocation: n x 1, cost allocated to the nodes in this scenario
% formula: phi_i = (1 - f*_i)(delta_i + sum_j L_ij) - sum_j (1 - f*_j) L_ji
%   = losses transmitted to the creditors of node i minus losses absorbed by
%   node i on its internal loans

Clearing = clearing_payments(Network, RiskyProfit);
LossRate = 1 - Clearing.PayFraction;                    % 1 - f*
Transmitted = Clearing.TotalDebt .* LossRate;           % (1 - f*_i) p_bar_i
Absorbed = Network.Liabilities' * LossRate;             % sum_j L_ji (1 - f*_j)
Allocation = Transmitted - Absorbed;
end
