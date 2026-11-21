function [Allocation, SubsetCosts] = allocation_intermediation(Network, RiskyProfit, Value)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% allocation_intermediation.m                                                 %
% Intermediation method (Section 4.4): participation lambda_i scales the size,%
% risky assets and equity of node i; internal liabilities have shared         %
% responsibility, L_ij(lambda) = sqrt(lambda_i lambda_j) L_ij; external       %
% liability substitutes for internal liability, cash for internal loans       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- Network: struct from make_network.m
% -- RiskyProfit: n x 1, profit on the risky assets, Theta * (a - 1)
% -- Value: 'S' (Shapley value) or 'AS' (Aumann-Shapley value)
% Output(s):
% -- Allocation: n x 1, cost allocated to the nodes in this scenario
% -- SubsetCosts: 2^n x 1, costs c(1_S) of all subsets S in the order of
%    all_subsets.m (Shapley value only; empty for 'AS')
% formula (AS): with shared responsibility, the Aumann-Shapley value is the
%   average of the solvency (borrower) and absorption (lender) allocations
%   (Section 4.4; Liu and Staum 2012)

NumNodes = size(Network.Liabilities, 1); % n
SubsetCosts = [];                        % filled for the Shapley value

if strcmp(Value, 'S')
    % ===== Shapley value: cost of every subset of participating nodes; a
    % non-participating node and all loans it is involved in are absent
    Subsets = all_subsets(NumNodes);
    SubsetCosts = zeros(2^NumNodes, 1);
    for k = 1:2^NumNodes
        Lambda = Subsets(k, :)';                           % participation 1_S
        [System, Profit] = counterfactual_system(Network, RiskyProfit, Lambda);
        SubsetCosts(k) = external_creditors_loss(System, Profit); % c(1_S)
    end
    Allocation = shapley_value(SubsetCosts, Subsets);

elseif strcmp(Value, 'AS')
    % ===== Aumann-Shapley value: average of borrower and lender responsibility
    Borrower = allocation_solvency(Network, RiskyProfit);   % Section 4.5
    Lender = allocation_absorption(Network, RiskyProfit);   % Section 4.6
    Allocation = (Borrower + Lender) / 2;

else
    error('Value must be ''S'' or ''AS''.');
end
end


function [System, Profit] = counterfactual_system(Network, RiskyProfit, Lambda)
% Counterfactual system of the intermediation scheme (Equations 15, 16)
% Input(s):
% -- Network, RiskyProfit: the real system and its profit Theta * (a - 1)
% -- Lambda: n x 1 participation vector
% Output(s):
% -- System: struct like Network with varsigma(lambda) = lambda varsigma,
%    Theta(lambda) = lambda Theta, gamma(lambda) = lambda gamma,
%    L_ij(lambda) = sqrt(lambda_i lambda_j) L_ij, and cash and external debt
%    from the accounting equation (Equation 16)
% -- Profit: n x 1, lambda_i Theta_i. (a - 1)

Size = Lambda .* Network.Size;                    % varsigma(lambda)
RiskyAssets = Lambda .* Network.RiskyAssets;      % Theta(lambda) 1
Equity = Lambda .* Network.Equity;                % gamma(lambda)
SharedScale = sqrt(Lambda * Lambda');             % [sqrt(lambda_i lambda_j)]
Liabilities = SharedScale .* Network.Liabilities; % L(lambda)
Cash = Size - RiskyAssets - sum(Liabilities, 1)';        % eta(lambda)
ExternalDebt = Size - Equity - sum(Liabilities, 2);      % delta(lambda)

System = make_network(Liabilities, ExternalDebt, Cash, RiskyAssets);
Profit = Lambda .* RiskyProfit;                   % Theta(lambda) (a - 1)
end
