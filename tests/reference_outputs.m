function Reference = reference_outputs()
% Outputs of the library functions and of the two examples on fixed inputs,
% used by make_reference_outputs.m (to save them) and run_tests.m (to
% compare with them)
% Output(s):
% -- Reference: struct with
%    .Example1, .Example2: outputs of the example scripts (no files written)
%    .Payments, .Zeta, .Allocations: cell arrays, one element per random
%     network (clearing payments, marginal prices, all_allocations.m)

Reference.Example1 = example1_two_node('');
Reference.Example2 = example2_six_node('');

Cases = random_networks(50, 7);
NumCases = length(Cases);
Reference.Payments = cell(NumCases, 1);
Reference.Zeta = cell(NumCases, 1);
Reference.Allocations = cell(NumCases, 1);
for c = 1:NumCases
    Clearing = clearing_payments(Cases(c).Network, Cases(c).RiskyProfit);
    Reference.Payments{c} = Clearing.Payments;
    Reference.Zeta{c} = Clearing.Zeta;
    Reference.Allocations{c} = all_allocations(Cases(c).Network, Cases(c).RiskyProfit);
end
end
