function [Cost, LossPerNode, Clearing] = external_creditors_loss(Network, RiskyProfit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% external_creditors_loss.m                                                   %
% Cost of a (real or counterfactual) system: the external creditors' loss     %
% (Section 3, Equation 7)                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The loss of the external creditors of each node, and the total. The loss
% of each node's external creditors is also the "external creditors' loss"
% row of Tables 3 and 5 (the same for Shapley and Aumann-Shapley).
% Input(s):
% -- Network: struct from make_network.m (or a counterfactual system)
% -- RiskyProfit: n x 1, profit on the risky assets, Theta * (a - 1)
% Output(s):
% -- Cost: scalar, l(e, delta, L) = delta' * (1 - f*)
% -- LossPerNode: n x 1, delta .* (1 - f*)
% -- Clearing: struct from clearing_payments.m
% formula: l(e, delta, L) = delta' * (1 - f*) (Equation 7)

Clearing = clearing_payments(Network, RiskyProfit); % p*, f*, zeta, ...
LossPerNode = Network.ExternalDebt .* (1 - Clearing.PayFraction); % delta_i (1 - f*_i)
Cost = sum(LossPerNode);                                          % delta' (1 - f*)
end
