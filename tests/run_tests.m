function run_tests()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run_tests.m                                                                 %
% Regression tests: (1) the current code reproduces the saved snapshot        %
% tests/reference_outputs.mat; (2) every method's allocations add up to the   %
% cost of the system; (3) it agrees with the original 2014 code.              %
% Run from the Code folder: addpath('tests'); run_tests                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TestsFolder = fileparts(mfilename('fullpath'));
CodeFolder = fileparts(TestsFolder);
addpath(fullfile(CodeFolder, 'functions'));
addpath(fullfile(CodeFolder, 'scripts'));
addpath(TestsFolder);

% ===== (1) Snapshot
Saved = load(fullfile(TestsFolder, 'reference_outputs.mat'));
Saved = Saved.Reference;
Current = reference_outputs();

Differences = [max(abs(Current.Example1.Allocations(:) - Saved.Example1.Allocations(:)));
               max(abs(Current.Example1.NodeLoss(:) - Saved.Example1.NodeLoss(:)));
               max(abs(Current.Example1.StandAlone(:) - Saved.Example1.StandAlone(:)));
               max(abs(Current.Example2.Allocations(:) - Saved.Example2.Allocations(:)));
               max(abs(Current.Example2.PayFraction - Saved.Example2.PayFraction));
               max(abs(Current.Example2.Zeta - Saved.Example2.Zeta))];
for c = 1:length(Saved.Allocations)
    Differences(end + 1) = max(abs(Current.Payments{c} - Saved.Payments{c})); %#ok<AGROW>
    Differences(end + 1) = max(abs(Current.Zeta{c} - Saved.Zeta{c})); %#ok<AGROW>
    Differences(end + 1) = max(abs(Current.Allocations{c}(:) - Saved.Allocations{c}(:))); %#ok<AGROW>
end
MaxSnapshot = max(Differences);
fprintf('run_tests: largest difference from the snapshot %.2e\n', MaxSnapshot);
if MaxSnapshot > 1e-8    % allocations are in units up to ~1e5: 1e-8 ~ rounding
    error('The results differ from tests/reference_outputs.mat.');
end

% ===== (2) Efficiency
test_efficiency();

% ===== (3) Original code
test_against_original();
fprintf('run_tests: all tests passed\n');
end
