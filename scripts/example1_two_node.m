function Results = example1_two_node(TablesFolder)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% example1_two_node.m                                                         %
% Example 1 (Section 4.1): two-node network of Figure 1 with the four         %
% scenarios of Table 2. Produces Table 2 (nodes' losses), Table 3 (systemic   %
% risk components) and the stand-alone risks quoted in Sections 4.2 to 4.4.  %
% Amounts in thousands as in Figure 1; Table 3 is in units (x 1000).          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- TablesFolder: folder for the CSV files (none written if empty)
% Output(s): struct Results with
% -- .Probabilities (1 x 4), .AssetReturns (3 x 4, a - 1), .NodeLoss (2 x 4,
%    1 - f*): Table 2
% -- .Allocations: 10 x 2, expected cost allocated by each method (Table 3)
% -- .MethodNames, .ValueNames: row labels of Table 3
% -- .StandAlone: 3 x 3, rows = external assets, transmission and
%    intermediation schemes; columns = stand-alone risk of node 1, of node 2,
%    and the risk of the real system (all expected costs, in units)
% formula: risk = expected cost, so the risk allocated to a node is the
%   probability-weighted sum of the costs allocated in the scenarios (Sec. 2)

% ===== Network of Figure 1 (in thousands)
% Node 1 ("downstream") lent L_21 = 100 to node 2 ("upstream")
Liabilities = [0   0;
               100 0];             % L(i,j) = borrowed by node i from node j
ExternalDebt = [400; 300];         % delta
Cash = [10; 10];                   % eta
Holdings = [300 0   0;             % Theta(i,k) = holding of node i in asset k
            0   300 100];
Network = make_network(Liabilities, ExternalDebt, Cash, Holdings * ones(3, 1));
% the equity gamma = [10; 10] follows from the accounting equation

% ===== Scenarios of Table 2: returns a - 1 of the three external assets
Probabilities = [0.88 0.04 0.04 0.04];
AssetReturns = [0.05  -71/120   0.10    -0.025;    % asset 1
                0.05   0.10    -0.025   -71/120;   % asset 2
                0.05  -0.10    -0.625    0.275];   % asset 3
% Table 2 prints -59.17% for -71/120; with this value node 1 loses exactly
% 41.875% in scenario 2 and node 2 loses exactly 35% in scenario 4
NumScenarios = length(Probabilities);   % 4
NumNodes = size(Liabilities, 1);        % 2

% ===== Allocations in each scenario and their expectation
Allocations = zeros(10, NumNodes);         % expected allocations (Table 3)
NodeLoss = zeros(NumNodes, NumScenarios);  % 1 - f* (Table 2)
StandAlone = zeros(3, 3);                  % see Output(s)
for Scenario = 1:NumScenarios
    RiskyProfit = Holdings * AssetReturns(:, Scenario);   % Theta (a - 1), per node
    Clearing = clearing_payments(Network, RiskyProfit);
    NodeLoss(:, Scenario) = 1 - Clearing.PayFraction;

    [ScenarioAllocations, MethodNames, ValueNames] = all_allocations(Network, RiskyProfit);
    Allocations = Allocations + Probabilities(Scenario) * ScenarioAllocations;

    %-- Subset costs c(1_S) of the schemes with a Shapley value; rows of
    % all_subsets(2): 1 = {}, 2 = {node 2}, 3 = {node 1}, 4 = {1, 2}
    [~, CostsExA] = allocation_external_assets(Network, RiskyProfit, 'S');
    [~, CostsTrans] = allocation_transmission_leverage(Network, RiskyProfit, 'S');
    [~, CostsInter] = allocation_intermediation(Network, RiskyProfit, 'S');
    SubsetCosts = [CostsExA'; CostsTrans'; CostsInter'];  % 3 schemes x 4 subsets
    StandAlone = StandAlone + Probabilities(Scenario) * SubsetCosts(:, [3 2 4]);
end
Allocations = 1000 * Allocations;          % thousands -> units, as in Table 3
StandAlone = 1000 * StandAlone;            % thousands -> units, as in the text

% ===== Outputs
Results.Probabilities = Probabilities;
Results.AssetReturns = AssetReturns;
Results.NodeLoss = NodeLoss;
Results.Allocations = Allocations;
Results.MethodNames = MethodNames;
Results.ValueNames = ValueNames;
Results.StandAlone = StandAlone;

if ~isempty(TablesFolder)
    %-- Table 2: scenarios (in percent)
    Table2 = table(100 * Probabilities', 100 * AssetReturns(1, :)', ...
        100 * AssetReturns(2, :)', 100 * AssetReturns(3, :)', ...
        100 * NodeLoss(1, :)', 100 * NodeLoss(2, :)', ...
        'VariableNames', {'Probability_pct', 'a1_minus_1_pct', 'a2_minus_1_pct', ...
        'a3_minus_1_pct', 'Loss_node1_pct', 'Loss_node2_pct'});
    writetable(Table2, fullfile(TablesFolder, 'Table2_Example1_Scenarios.csv'));

    %-- Table 3: systemic risk components (in units)
    Table3 = table(MethodNames, ValueNames, Allocations(:, 1), Allocations(:, 2), ...
        'VariableNames', {'Method', 'Value', 'Downstream_node1', 'Upstream_node2'});
    writetable(Table3, fullfile(TablesFolder, 'Table3_Example1_Components.csv'));

    %-- Stand-alone risks and interaction quoted in Sections 4.2-4.4
    Interaction = StandAlone(:, 3) - StandAlone(:, 1) - StandAlone(:, 2); % system - sum of stand-alone
    TextTable = table({'External assets'; 'Transmission and leverage'; 'Intermediation'}, ...
        StandAlone(:, 1), StandAlone(:, 2), StandAlone(:, 3), Interaction, ...
        'VariableNames', {'Scheme', 'StandAlone_node1', 'StandAlone_node2', ...
        'System', 'Interaction'});
    writetable(TextTable, fullfile(TablesFolder, 'Text_Example1_StandAloneRisks.csv'));
end
end
