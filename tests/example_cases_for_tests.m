function Cases = example_cases_for_tests()
% The scenarios of Examples 1 and 2 as test cases (same networks as in
% scripts/example1_two_node.m and scripts/example2_six_node.m)
% Output(s):
% -- Cases: struct array with .Network and .RiskyProfit (5 cases)

Holdings = [300 0 0; 0 300 100];
Network1 = make_network([0 0; 100 0], [400; 300], [10; 10], Holdings * ones(3, 1));
AssetReturns = [0.05 -71/120 0.10 -0.025; 0.05 0.10 -0.025 -71/120; 0.05 -0.10 -0.625 0.275];
Cases = struct('Network', {}, 'RiskyProfit', {});
for s = 1:4
    Cases(s).Network = Network1;
    Cases(s).RiskyProfit = Holdings * AssetReturns(:, s);
end

Liabilities = zeros(6, 6);                  % L of Figure 2
Liabilities(3, 1) = 50;  Liabilities(1, 2) = 200; Liabilities(2, 3) = 200;
Liabilities(4, 3) = 200; Liabilities(6, 3) = 200; Liabilities(5, 4) = 200;
Liabilities(3, 5) = 50;  Liabilities(1, 6) = 200; Liabilities(5, 6) = 200;
Risky = [500; 750; 350; 0; 500; 550];
Network2 = make_network(Liabilities, [150; 750; 875; 750; 150; 750], [50; 50; 50; 800; 50; 50], Risky);
Cases(5).Network = Network2;
Cases(5).RiskyProfit = Risky .* [-0.40; 0.10; -0.20; 0; -0.40; 0.10];
end
