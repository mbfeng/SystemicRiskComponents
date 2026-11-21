function MaxGap = test_efficiency()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% test_efficiency.m                                                           %
% Efficiency check: every method's allocations must add up to the cost of the %
% real system, c(1) - c(0) = c(1) (Shapley and Aumann-Shapley values are      %
% efficient). Checked on the two examples and on 300 random networks.         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output(s):
% -- MaxGap: largest |sum of allocations - cost| relative to the largest
%    balance sheet (error if above 1e-9)

CodeFolder = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(CodeFolder, 'functions'));
addpath(fullfile(CodeFolder, 'tests'));

Cases = [example_cases_for_tests(), random_networks(300, 2014)];
MaxGap = 0;
for c = 1:length(Cases)
    Network = Cases(c).Network;
    Cost = external_creditors_loss(Network, Cases(c).RiskyProfit);    % c(1)
    Allocations = all_allocations(Network, Cases(c).RiskyProfit);     % 10 x n
    Gaps = abs(sum(Allocations, 2) - Cost) / max(Network.Size);       % one per method
    MaxGap = max(MaxGap, max(Gaps));
end

fprintf('test_efficiency: %d networks, largest relative gap %.2e\n', length(Cases), MaxGap);
if MaxGap > 1e-9
    error('Some allocations do not add up to the cost of the system.');
end
end
