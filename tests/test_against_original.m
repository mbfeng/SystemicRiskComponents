function MaxDifference = test_against_original()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% test_against_original.m                                                     %
% Compares the restructured code with the original 2014 code (folder          %
% original_2014/) on the two examples of the paper and on 300 random          %
% networks: all ten methods, clearing payments and sensitivities zeta.        %
% The external-assets Aumann-Shapley value may differ only where the original %
% breakpoint search skipped a breakpoint (see README); there the new          %
% allocations must add up to the cost and the original ones must not.         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output(s):
% -- MaxDifference: largest absolute difference over all cases, relative to
%    the size of the network's balance sheets (error if above 1e-9)
% Note: the original code takes each node's portfolio return; the new code
% takes the profit Theta (a - 1). The original two-node script used a 0%
% return for node 2 in scenario 2, the new one the 5% implied by Table 2;
% the published results are the same with both (see README).

CodeFolder = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(CodeFolder, 'functions'));
addpath(fullfile(CodeFolder, 'original_2014'));   % calcClearingPayments, calc_*
addpath(fullfile(CodeFolder, 'tests'));

% ===== Test cases: the two examples and random networks
Cases = random_networks(300, 2014);
Example = example_cases_for_tests();
Cases = [Example, Cases];

MaxDifference = 0;
NumCorrected = 0;   % cases where the external-assets A-S value was corrected
for c = 1:length(Cases)
    Network = Cases(c).Network;
    RiskyProfit = Cases(c).RiskyProfit;

    %-- New code
    NewAllocations = all_allocations(Network, RiskyProfit);
    NewClearing = clearing_payments(Network, RiskyProfit);

    %-- Original code
    OldAllocations = original_allocations(Network, RiskyProfit);
    PortfolioReturn = zeros(size(RiskyProfit));
    HasRisky = Network.RiskyAssets > 0;
    PortfolioReturn(HasRisky) = RiskyProfit(HasRisky) ./ Network.RiskyAssets(HasRisky);
    OldClearing = calcClearingPayments(Network.Liabilities, Network.ExternalDebt, ...
        Network.Cash, Network.RiskyAssets, PortfolioReturn);

    %-- Differences relative to the largest balance sheet
    Scale = max(Network.Size);
    Cost = external_creditors_loss(Network, RiskyProfit);
    if max(abs(NewAllocations(3, :) - OldAllocations(3, :))) / Scale > 1e-9
        % external assets A-S differs: allowed only if the original skipped a
        % breakpoint, i.e., its allocations do not add up to the cost
        NewGap = abs(sum(NewAllocations(3, :)) - Cost) / Scale;
        OldGap = abs(sum(OldAllocations(3, :)) - Cost) / Scale;
        if NewGap > 1e-9 || OldGap < 1e-9
            error('External assets A-S differs from the original in case %d.', c);
        end
        NumCorrected = NumCorrected + 1;
        OldAllocations(3, :) = NewAllocations(3, :);   % excluded from the comparison
    end
    Differences = [abs(NewAllocations(:) - OldAllocations(:)) / Scale;
                   abs(NewClearing.Payments - OldClearing.ClearingP) / Scale;
                   abs(NewClearing.Zeta - (-OldClearing.Grad_e))];
    MaxDifference = max(MaxDifference, max(Differences));
end

fprintf('test_against_original: %d networks, largest relative difference %.2e\n', ...
    length(Cases), MaxDifference);
fprintf('  external assets A-S corrected (original skipped a breakpoint) in %d networks\n', NumCorrected);
if MaxDifference > 1e-9
    error('The restructured code differs from the original code.');
end
end


function Allocations = original_allocations(Network, RiskyProfit)
% The ten allocations of all_allocations.m computed with the original code
% Input(s):
% -- Network, RiskyProfit: as in all_allocations.m
% Output(s):
% -- Allocations: 10 x n, rows in the order of all_allocations.m

% short names to keep the calls of the original functions on one line
Liab = Network.Liabilities;                 % L
Debt = Network.ExternalDebt;                % delta
Cash = Network.Cash;                        % eta
Risky = Network.RiskyAssets;                % Theta 1
Return = zeros(size(RiskyProfit));          % portfolio return a - 1 per node
HasRisky = Risky > 0;
Return(HasRisky) = RiskyProfit(HasRisky) ./ Risky(HasRisky);

Clearing = calcClearingPayments(Liab, Debt, Cash, Risky, Return);
Allocations = zeros(10, size(Liab, 1));
Allocations(1, :) = calc_external_creditor_loss(Debt, Clearing.PayFrac)';
Allocations(2, :) = calc_external_assets(Liab, Debt, Cash, Risky, Return, 'S')';
Allocations(3, :) = calc_external_assets(Liab, Debt, Cash, Risky, Return, 'AS')';
Allocations(4, :) = calc_leverage(Liab, Debt, Cash, Risky, Return, 'S')';
Allocations(5, :) = calc_leverage(Liab, Debt, Cash, Risky, Return, 'AS')';
Allocations(6, :) = calc_const_leverage_shared(Liab, Debt, Cash, Risky, Return, 'S')';
Allocations(7, :) = calc_const_leverage_shared(Liab, Debt, Cash, Risky, Return, 'AS')';
Allocations(8, :) = calc_const_leverage_borrower(Liab, Debt, Cash, Risky, Return, 'AS')';
Allocations(9, :) = calc_const_leverage_lender(Liab, Debt, Cash, Risky, Return, 'AS')';
Allocations(10, :) = calc_borrowing_provides_cash(Liab, Debt, Cash, Risky, Return, 'AS')';
end
