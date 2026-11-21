function Allocation = shapley_value(SubsetCosts, Subsets)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% shapley_value.m                                                             %
% Shapley value of a cost function given on all subsets (Section 2, Eq. 2)    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- SubsetCosts: 2^n x 1, cost c(1_S) of the counterfactual system in which
%    exactly the nodes in subset S participate (row k <-> row k of Subsets)
% -- Subsets: 2^n x n, from all_subsets.m; row k is the indicator vector 1_S
% Output(s):
% -- Allocation: n x 1, Shapley value phi^S
% formula: phi^S_i = (1/n!) sum_{S not containing i} (n-|S|-1)! |S|! *
%          (c(1_{S + i}) - c(1_S))                              (Equation 2)

NumNodes = size(Subsets, 2);        % n
Allocation = zeros(NumNodes, 1);    % phi^S

for Node = 1:NumNodes
    Without = find(Subsets(:, Node) == 0);  % rows of subsets S without node i
    % In the binary ordering of all_subsets.m, adding node i to S adds
    % 2^(n-i) to the row number
    With = Without + 2^(NumNodes - Node);   % rows of S + {i}
    for k = 1:length(Without)
        SizeS = sum(Subsets(Without(k), :));                     % |S|
        Weight = factorial(NumNodes - SizeS - 1) * factorial(SizeS); % (n-|S|-1)! |S|!
        Increment = SubsetCosts(With(k)) - SubsetCosts(Without(k)); % c(S + i) - c(S)
        Allocation(Node) = Allocation(Node) + Weight * Increment;
    end
end
Allocation = Allocation / factorial(NumNodes); % divide by n!
end
