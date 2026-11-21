function make_reference_outputs()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make_reference_outputs.m                                                    %
% Saves the outputs of every library function on fixed inputs (the examples  %
% of the paper and 50 random networks) to tests/reference_outputs.mat.        %
% run_tests.m compares later versions of the code with this snapshot.         %
% Rerun only when a change of the results is intended.                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TestsFolder = fileparts(mfilename('fullpath'));
CodeFolder = fileparts(TestsFolder);
addpath(fullfile(CodeFolder, 'functions'));
addpath(fullfile(CodeFolder, 'scripts'));
addpath(TestsFolder);

Reference = reference_outputs(); %#ok<NASGU> (saved below)
save(fullfile(TestsFolder, 'reference_outputs.mat'), 'Reference');
fprintf('make_reference_outputs: saved tests/reference_outputs.mat\n');
end
