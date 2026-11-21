function Results = example2_six_node(TablesFolder)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% example2_six_node.m                                                         %
% Example 2 (Section 4.1): one scenario of the six-node network of Figure 2   %
% and Table 4. Produces Table 4 (balance sheets, payment fractions f* and     %
% sensitivities zeta) and Table 5 (cost allocations, in units).              %
% Amounts in thousands as in Figure 2 and Table 4.                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- TablesFolder: folder for the CSV files (none written if empty)
% Output(s): struct Results with
% -- .Network: struct from make_network.m; .PortfolioReturn: 6 x 1
% -- .PayFraction, .Zeta: 6 x 1 (last two columns of Table 4)
% -- .Allocations: 10 x 6 (Table 5); .MethodNames, .ValueNames: its rows
% -- .SystemCost: cost of the system in units (134,571 in Section 4.1)

% ===== Network of Figure 2 (in thousands); L(i,j) = borrowed by i from j,
% an arrow j -> i in Figure 2
Liabilities = zeros(6, 6);
Liabilities(3, 1) = 50;     % node 1 lent 50 to node 3
Liabilities(1, 2) = 200;    % node 2 lent 200 to node 1
Liabilities(2, 3) = 200;    % node 3 lent 200 to nodes 2, 4 and 6
Liabilities(4, 3) = 200;
Liabilities(6, 3) = 200;
Liabilities(5, 4) = 200;    % node 4 lent 200 to node 5
Liabilities(3, 5) = 50;     % node 5 lent 50 to node 3
Liabilities(1, 6) = 200;    % node 6 lent 200 to nodes 1 and 5
Liabilities(5, 6) = 200;

% Table 4
ExternalDebt = [150; 750; 875; 750; 150; 750];    % delta
Cash = [50; 50; 50; 800; 50; 50];                 % eta
RiskyAssets = [500; 750; 350; 0; 500; 550];       % Theta 1 (one portfolio per node)
PortfolioReturn = [-0.40; 0.10; -0.20; 0; -0.40; 0.10]; % a - 1 of each portfolio
Network = make_network(Liabilities, ExternalDebt, Cash, RiskyAssets);
% sizes and equity of Table 4 follow from the accounting equation

% ===== The single scenario
RiskyProfit = RiskyAssets .* PortfolioReturn;     % Theta (a - 1)
Clearing = clearing_payments(Network, RiskyProfit);
[Allocations, MethodNames, ValueNames] = all_allocations(Network, RiskyProfit);
Allocations = 1000 * Allocations;                 % thousands -> units (Table 5)
SystemCost = 1000 * external_creditors_loss(Network, RiskyProfit);

% ===== Outputs
Results.Network = Network;
Results.PortfolioReturn = PortfolioReturn;
Results.PayFraction = Clearing.PayFraction;
Results.Zeta = Clearing.Zeta;
Results.Allocations = Allocations;
Results.MethodNames = MethodNames;
Results.ValueNames = ValueNames;
Results.SystemCost = SystemCost;

if ~isempty(TablesFolder)
    %-- Table 4: balance sheets (in thousands) and outcomes
    Node = (1:6)';
    Table4 = table(Node, Network.Size, Network.Equity, ExternalDebt, Cash, ...
        RiskyAssets, 100 * PortfolioReturn, Clearing.PayFraction, Clearing.Zeta, ...
        'VariableNames', {'Node', 'Size', 'Equity', 'ExternalDebt', 'Cash', ...
        'RiskyAssets', 'PortfolioReturn_pct', 'PaymentFraction', 'Sensitivity_zeta'});
    writetable(Table4, fullfile(TablesFolder, 'Table4_Example2_BalanceSheets.csv'));

    %-- Table 5: cost allocations (in units)
    Table5 = table(MethodNames, ValueNames, Allocations(:, 1), Allocations(:, 2), ...
        Allocations(:, 3), Allocations(:, 4), Allocations(:, 5), Allocations(:, 6), ...
        'VariableNames', {'Method', 'Value', 'Node1', 'Node2', 'Node3', 'Node4', ...
        'Node5', 'Node6'});
    writetable(Table5, fullfile(TablesFolder, 'Table5_Example2_Allocations.csv'));
end
end
