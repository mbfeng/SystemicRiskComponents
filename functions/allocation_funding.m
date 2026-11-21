function Allocation = allocation_funding(Network, RiskyProfit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% allocation_funding.m                                                        %
% Funding method (Section 4.7, Online Supplement C.5): participation scales   %
% equity, external debt and risky assets; lender responsibility for internal  %
% loans; borrowing provides cash. Aumann-Shapley value (closed form; the      %
% cost function is homogeneous)                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- Network: struct from make_network.m
% -- RiskyProfit: n x 1, profit on the risky assets, Theta * (a - 1)
% Output(s):
% -- Allocation: n x 1, cost allocated to the nodes in this scenario
% formula: phi_i = delta_i (1 - f*_i) + zeta_i (1 - f*_i) sum_j L_ij
%                  - sum_j L_ji zeta_j (1 - f*_j)

Clearing = clearing_payments(Network, RiskyProfit);
LossRate = 1 - Clearing.PayFraction;                     % 1 - f*
InternalDebt = sum(Network.Liabilities, 2);              % L 1
ExternalLoss = Network.ExternalDebt .* LossRate;         % delta_i (1 - f*_i)
OwnFunding = InternalDebt .* Clearing.Zeta .* LossRate;  % zeta_i (1 - f*_i) (L 1)_i
LendersFunding = Network.Liabilities' * (Clearing.Zeta .* LossRate); % sum_j L_ji zeta_j (1 - f*_j)
Allocation = ExternalLoss + OwnFunding - LendersFunding;
end
