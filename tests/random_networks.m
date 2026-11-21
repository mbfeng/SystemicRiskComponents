function Cases = random_networks(NumCases, Seed)
% Random test networks with one scenario each, for the regression tests
% Input(s):
% -- NumCases: number of networks
% -- Seed: seed of the random number generator (restored afterwards)
% Output(s):
% -- Cases: struct array with .Network (from make_network.m) and
%    .RiskyProfit (n x 1); 2 to 5 nodes, about half of the possible loans
%    present, portfolio returns between -60% and +30% (many defaults)

SavedGenerator = rng;          % restore the caller's generator at the end
rng(Seed, 'twister');
Cases = struct('Network', {}, 'RiskyProfit', {});
for c = 1:NumCases
    NumNodes = randi([2 5]);                                % n
    HasLoan = rand(NumNodes) < 0.5;                         % which loans exist
    HasLoan(logical(eye(NumNodes))) = false;                % no self-loans
    Liabilities = HasLoan .* round(100 * rand(NumNodes));   % L
    ExternalDebt = round(50 + 300 * rand(NumNodes, 1));     % delta > 0
    Cash = round(5 + 40 * rand(NumNodes, 1));               % eta > 0
    InternalLoans = sum(Liabilities, 1)';
    InternalDebt = sum(Liabilities, 2);
    Equity = round(5 + 30 * rand(NumNodes, 1));             % gamma > 0
    % risky assets from the accounting equation (made non-negative)
    RiskyAssets = Equity + ExternalDebt + InternalDebt - Cash - InternalLoans;
    RiskyAssets = max(RiskyAssets, 0);
    Network = make_network(Liabilities, ExternalDebt, Cash, RiskyAssets);
    PortfolioReturn = -0.6 + 0.9 * rand(NumNodes, 1);       % a - 1 in [-0.6, 0.3]
    Cases(c).Network = Network;
    Cases(c).RiskyProfit = RiskyAssets .* PortfolioReturn;
end
rng(SavedGenerator);
end
