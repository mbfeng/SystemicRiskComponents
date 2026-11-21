function [Allocation, SubsetCosts] = allocation_transmission_leverage(Network, RiskyProfit, Value)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% allocation_transmission_leverage.m                                          %
% Transmission (Shapley) and leverage (Aumann-Shapley) methods                %
% (Section 4.3, Online Supplement C.2)                                        %
% Participation lambda_i scales the liabilities of node i (borrower           %
% responsibility); equity substitutes for liability, cash for internal loans; %
% sizes and risky assets are fixed                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- Network: struct from make_network.m
% -- RiskyProfit: n x 1, profit on the risky assets, Theta * (a - 1)
% -- Value: 'S' (Shapley value: transmission method) or 'AS' (Aumann-Shapley
%    value: leverage method)
% Output(s):
% -- Allocation: n x 1, cost allocated to the nodes in this scenario
% -- SubsetCosts: 2^n x 1, costs c(1_S) of all subsets S in the order of
%    all_subsets.m (Shapley value only; empty for 'AS')
% formula (AS): phi_i = sum_j omega_j dc/dlambda_i(mu_j 1), with
%   dc/dlambda_i(lambda) = 1{i red} (delta_i + sum_j zeta_j(lambda) L_ij)

NumNodes = size(Network.Liabilities, 1); % n
SubsetCosts = [];                        % filled for the Shapley value

if strcmp(Value, 'S')
    % ===== Shapley value: cost of every subset of participating nodes
    Subsets = all_subsets(NumNodes);
    SubsetCosts = zeros(2^NumNodes, 1);
    for k = 1:2^NumNodes
        Lambda = Subsets(k, :)';                           % participation 1_S
        System = counterfactual_system(Network, Lambda);
        SubsetCosts(k) = external_creditors_loss(System, RiskyProfit); % c(1_S)
    end
    Allocation = shapley_value(SubsetCosts, Subsets);

elseif strcmp(Value, 'AS')
    % ===== Aumann-Shapley value
    %-- Breakpoints: start at t = 1 and decrease t until a red node of the
    % system t*1 becomes borderline (Online Supplement C.2). Decreasing t
    % can turn red nodes green but not green nodes red.
    TotalDebt = Network.ExternalDebt + sum(Network.Liabilities, 2); % p_bar of the real system
    Scale = 1;            % current t
    Breakpoints = 1;      % t_1 = 1 > t_2 > ... > 0
    while Scale > 0
        System = counterfactual_system(Network, Scale * ones(NumNodes, 1));
        Clearing = clearing_payments(System, RiskyProfit);
        Red = Clearing.Red;

        % Slope of the payments of red nodes with respect to t, from the
        % right derivatives: p'_i = - sum_{j red} dp_i/de_j sum_{k red} L_kj
        PaymentSlope = zeros(NumNodes, 1);
        LoansFromRed = Network.Liabilities(Red, Red)' * ones(sum(Red), 1); % sum_{k red} L_kj
        PaymentSlope(Red) = -Clearing.RightDeriv(Red, Red) * LoansFromRed;

        % Distance to the borderline (payment t p_bar_j reached) of each red node
        Distance = inf(NumNodes, 1);
        Moving = Red & (PaymentSlope < TotalDebt);
        Distance(Moving) = (Scale * TotalDebt(Moving) - Clearing.Payments(Moving)) ...
            ./ (TotalDebt(Moving) - PaymentSlope(Moving));

        Step = min(Distance);   % omega = min_j omega_j
        if isinf(Step) || Scale - Step <= 0
            Scale = 0;          % no more breakpoints in (0, t)
        else
            Scale = Scale - Step;
        end
        Breakpoints(end + 1) = Scale; %#ok<AGROW> (few breakpoints)
    end

    %-- Integral of the gradient over [0, 1]: constant between breakpoints
    Breakpoints = sort(Breakpoints);                        % increasing
    Widths = diff(Breakpoints);                             % omega_j
    Midpoints = (Breakpoints(1:end-1) + Breakpoints(2:end)) / 2; % mu_j
    Allocation = zeros(NumNodes, 1);
    for j = 1:length(Widths)
        System = counterfactual_system(Network, Midpoints(j) * ones(NumNodes, 1));
        Clearing = clearing_payments(System, RiskyProfit);
        % dc/dlambda_i = 1{i red} (delta_i + sum_j L_ij zeta_j), with the
        % liabilities of the real system
        Gradient = Clearing.Red .* (Network.ExternalDebt + Network.Liabilities * Clearing.Zeta);
        Allocation = Allocation + Widths(j) * Gradient;
    end

else
    error('Value must be ''S'' or ''AS''.');
end
end


function System = counterfactual_system(Network, Lambda)
% Counterfactual system of the transmission and leverage scheme (Section 4.3)
% Input(s):
% -- Network: the real system
% -- Lambda: n x 1 participation vector
% Output(s):
% -- System: struct like Network with delta_i(lambda) = lambda_i delta_i,
%    L_ij(lambda) = lambda_i L_ij (borrower responsibility) and cash
%    eta_i(lambda) = varsigma_i - Theta_i. 1 - sum_j L_ji(lambda); the risky
%    assets (and so the profit Theta (a - 1)) are unchanged

ExternalDebt = Lambda .* Network.ExternalDebt;      % delta(lambda)
Liabilities = Lambda .* Network.Liabilities;        % row i scaled by lambda_i
InternalLoans = sum(Liabilities, 1)';               % L(lambda)' 1
Cash = Network.Size - Network.RiskyAssets - InternalLoans; % cash substitutes for internal loans
System = make_network(Liabilities, ExternalDebt, Cash, Network.RiskyAssets);
end
