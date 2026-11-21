function [Allocations, MethodNames, ValueNames] = all_allocations(Network, RiskyProfit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% all_allocations.m                                                           %
% Cost allocations of all methods of the paper for one scenario, in the row   %
% order of Tables 3 and 5                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- Network: struct from make_network.m
% -- RiskyProfit: n x 1, profit on the risky assets, Theta * (a - 1)
% Output(s):
% -- Allocations: 10 x n, row m = allocation of method m to the n nodes
% -- MethodNames, ValueNames: 10 x 1 cell arrays, the first two columns of
%    Tables 3 and 5 (balance-sheet scheme and Shapley / Aumann-Shapley)

MethodNames = {"External creditors' loss"; 'External assets'; 'External assets'; ...
    'Transmission'; 'Leverage'; 'Intermediation'; 'Intermediation'; ...
    'Solvency'; 'Absorption'; 'Funding'};
ValueNames = {'Both'; 'Shapley'; 'Aumann-Shapley'; 'Shapley'; 'Aumann-Shapley'; ...
    'Shapley'; 'Aumann-Shapley'; 'Aumann-Shapley'; 'Aumann-Shapley'; 'Aumann-Shapley'};

NumNodes = size(Network.Liabilities, 1);
Allocations = zeros(10, NumNodes);
[~, LossPerNode] = external_creditors_loss(Network, RiskyProfit);
Allocations(1, :) = LossPerNode';                                          % Section 3
Allocations(2, :) = allocation_external_assets(Network, RiskyProfit, 'S')';  % Section 4.2
Allocations(3, :) = allocation_external_assets(Network, RiskyProfit, 'AS')';
Allocations(4, :) = allocation_transmission_leverage(Network, RiskyProfit, 'S')';  % Section 4.3
Allocations(5, :) = allocation_transmission_leverage(Network, RiskyProfit, 'AS')';
Allocations(6, :) = allocation_intermediation(Network, RiskyProfit, 'S')';   % Section 4.4
Allocations(7, :) = allocation_intermediation(Network, RiskyProfit, 'AS')';
Allocations(8, :) = allocation_solvency(Network, RiskyProfit)';              % Section 4.5
Allocations(9, :) = allocation_absorption(Network, RiskyProfit)';            % Section 4.6
Allocations(10, :) = allocation_funding(Network, RiskyProfit)';              % Section 4.7
end
