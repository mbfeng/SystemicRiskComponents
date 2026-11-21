function [Allocation, SubsetCosts] = allocation_external_assets(Network, RiskyProfit, Value)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% allocation_external_assets.m                                                %
% External-assets balance-sheet scheme (Section 4.2, Online Supplement C.1)   %
% Participation lambda_i scales the risky assets of node i; cash substitutes  %
% for risky assets; sizes, equity and liabilities are fixed                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- Network: struct from make_network.m
% -- RiskyProfit: n x 1, profit on the risky assets, Theta * (a - 1)
% -- Value: 'S' (Shapley value) or 'AS' (Aumann-Shapley value)
% Output(s):
% -- Allocation: n x 1, cost allocated to the nodes in this scenario
% -- SubsetCosts: 2^n x 1, costs c(1_S) of all subsets S in the order of
%    all_subsets.m (Shapley value only; empty for 'AS')
% formula (AS): phi_i = (Theta_i. (1 - a)) * sum_j omega_j zeta_i(mu_j 1),
%   omega_j, mu_j = widths and midpoints of the intervals of t in [0, 1]
%   between the breakpoints where a node of the system t*1 is borderline
%   (zeta is constant on each interval)

NumNodes = size(Network.Liabilities, 1); % n
SubsetCosts = [];                        % filled for the Shapley value

if strcmp(Value, 'S')
    % ===== Shapley value: cost of every subset of participating nodes
    Subsets = all_subsets(NumNodes);
    SubsetCosts = zeros(2^NumNodes, 1);
    for k = 1:2^NumNodes
        Lambda = Subsets(k, :)';                          % participation 1_S
        [System, Profit] = counterfactual_system(Network, RiskyProfit, Lambda);
        SubsetCosts(k) = external_creditors_loss(System, Profit); % c(1_S)
    end
    Allocation = shapley_value(SubsetCosts, Subsets);

elseif strcmp(Value, 'AS')
    % ===== Aumann-Shapley value
    %-- Breakpoints: start at t = 1 and step down. The procedure of Online
    % Supplement C.1 predicts the next t at which a node of the system t*1
    % becomes borderline. Its slopes use left or right derivatives by the
    % sign of each node's profit; when a borderline node changes colour
    % because of other nodes' income, this can predict a wrong breakpoint
    % and skip the true one. Each predicted interval is therefore checked:
    % if the node colours just below t and just above the predicted
    % breakpoint differ, a breakpoint was skipped and it is located by
    % bisection on the colours (see README, "Difference from the published
    % article").
    Scale = 1;            % current t
    Breakpoints = 1;      % t_1 = 1 > t_2 > ... > 0
    while Scale > 0
        [System, Profit] = counterfactual_system(Network, RiskyProfit, Scale * ones(NumNodes, 1));
        Clearing = clearing_payments(System, Profit);

        % Decreasing t decreases the income of node j if its profit is
        % positive: use the left derivative for that node, else the right one
        UseLeft = RiskyProfit > 0;                      % nodes j (columns)
        PaymentToIncome = Clearing.RightDeriv;          % d p / d e
        PaymentToIncome(:, UseLeft) = Clearing.LeftDeriv(:, UseLeft);

        % Derivatives with respect to t (de/dt = profit) of the payments
        % and of the time-1 equity (Liu and Staum 2010)
        PaymentSlope = PaymentToIncome * RiskyProfit;     % p'(t)
        EquityToIncome = eye(NumNodes) + (Clearing.Pi' - eye(NumNodes)) * PaymentToIncome;
        EquitySlope = EquityToIncome * RiskyProfit;       % v'(t)

        % Distance omega_j to the next borderline for each node
        Distance = inf(NumNodes, 1);
        % red node that pays more as t decreases: reaches p_bar
        RedUp = Clearing.Red & (PaymentSlope < 0);
        Distance(RedUp) = (Clearing.Payments(RedUp) - Clearing.TotalDebt(RedUp)) ./ PaymentSlope(RedUp);
        % green node whose equity falls as t decreases: reaches v = 0
        GreenDown = Clearing.Green & (EquitySlope > 0);
        Distance(GreenDown) = Clearing.Equity(GreenDown) ./ EquitySlope(GreenDown);

        Step = min(Distance);   % omega = min_j omega_j
        if isinf(Step) || Scale <= Step
            Predicted = 0;      % no more breakpoints predicted in (0, t)
        else
            Predicted = Scale - Step;
        end

        % Check the predicted interval (Predicted, Scale) for a skipped breakpoint
        NextScale = first_colour_change(Network, RiskyProfit, Predicted, Scale);
        if NextScale >= Scale
            error('Breakpoint search made no progress.');
        end
        Scale = NextScale;
        Breakpoints(end + 1) = Scale; %#ok<AGROW> (few breakpoints)
    end

    %-- Integral of zeta(t 1) over [0, 1]: zeta is constant between breakpoints
    Breakpoints = sort(Breakpoints);                        % increasing
    Widths = diff(Breakpoints);                             % omega_j
    Midpoints = (Breakpoints(1:end-1) + Breakpoints(2:end)) / 2; % mu_j
    IntegralZeta = zeros(NumNodes, 1);                      % int_0^1 zeta(t 1) dt
    for j = 1:length(Widths)
        [System, Profit] = counterfactual_system(Network, RiskyProfit, Midpoints(j) * ones(NumNodes, 1));
        Clearing = clearing_payments(System, Profit);
        IntegralZeta = IntegralZeta + Widths(j) * Clearing.Zeta;
    end

    Allocation = IntegralZeta .* (-RiskyProfit); % (Theta (1 - a)) * average zeta

else
    error('Value must be ''S'' or ''AS''.');
end
end


function Breakpoint = first_colour_change(Network, RiskyProfit, Predicted, Scale)
% Largest t in [Predicted, Scale) at which the node colours of the system
% t*1 change, going down from Scale; Predicted if they do not change in the
% interval (the predicted breakpoint is then correct)
% Input(s):
% -- Network, RiskyProfit: the real system and its profit Theta * (a - 1)
% -- Predicted: breakpoint predicted by the Online Supplement C.1 procedure
% -- Scale: current breakpoint t
% Output(s):
% -- Breakpoint: the next breakpoint below Scale
% Note: the colours are compared at points a small fraction (1e-6) of the
% interval inside its ends, because both ends are breakpoints where some
% node is borderline. Colour changes are located to 1e-14.

Width = Scale - Predicted;               % length of the predicted interval
Upper = Scale - 1e-6 * Width;            % just below the current breakpoint
Lower = Predicted + 1e-6 * Width;        % just above the predicted breakpoint
ColoursUpper = node_colours(Network, RiskyProfit, Upper);
ColoursLower = node_colours(Network, RiskyProfit, Lower);
if isequal(ColoursUpper, ColoursLower)
    Breakpoint = Predicted;              % no skipped breakpoint
    return
end

% Bisection: keep the colours of High equal to those just below Scale and
% the colours of Low different from them
High = Upper;
Low = Lower;
while High - Low > 1e-14
    Middle = (Low + High) / 2;
    if isequal(node_colours(Network, RiskyProfit, Middle), ColoursUpper)
        High = Middle;
    else
        Low = Middle;
    end
end
Breakpoint = (Low + High) / 2;
end


function Colours = node_colours(Network, RiskyProfit, Scale)
% Red and green nodes of the counterfactual system Scale * 1, decided with a
% rounding-level tolerance (relative 1e-12) instead of the 1e-8 of
% clearing_payments.m: with 1e-8, a node near a breakpoint already counts as
% borderline, which would place breakpoints about 1e-7 away from the true
% crossing
% Output(s):
% -- Colours: 2n x 1 logical, [red nodes; green nodes]
[System, Profit] = counterfactual_system(Network, RiskyProfit, Scale * ones(size(RiskyProfit)));
Clearing = clearing_payments(System, Profit);
Rounding = 1e-12 * max(1, Clearing.TotalDebt);            % per node
Red = Clearing.Payments < Clearing.TotalDebt - Rounding;  % p* < p_bar
Green = Clearing.Equity > Rounding;                       % v* > 0
Colours = [Red; Green];
end


function [System, Profit] = counterfactual_system(Network, RiskyProfit, Lambda)
% Counterfactual system of the external-assets scheme (Section 4.2)
% Input(s):
% -- Network, RiskyProfit: the real system and its profit Theta * (a - 1)
% -- Lambda: n x 1 participation vector
% Output(s):
% -- System: struct like Network, with Theta_i.(lambda) = lambda_i Theta_i.
%    and cash eta_i(lambda) = varsigma_i - sum_j L_ji - lambda_i Theta_i. 1
% -- Profit: n x 1, lambda_i Theta_i. (a - 1)

RiskyAssets = Lambda .* Network.RiskyAssets;        % Theta(lambda) 1
InternalLoans = sum(Network.Liabilities, 1)';       % L' 1 (fixed)
Cash = Network.Size - InternalLoans - RiskyAssets;  % cash substitutes for risky assets

System = make_network(Network.Liabilities, Network.ExternalDebt, Cash, RiskyAssets);
Profit = Lambda .* RiskyProfit;                     % Theta(lambda) (a - 1)
end
