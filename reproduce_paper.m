%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reproduce_paper.m                                                           %
% Entry point: reproduces Tables 2-5 and the numbers quoted in Section 4 of   %
% Staum, Feng and Liu (2016), "Systemic risk components in a network model of %
% contagion", IIE Transactions 48(6), 501-510, and checks them against the    %
% published values. Runs in a few seconds. Run from this folder.              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ===== Paths
CodeFolder = fileparts(mfilename('fullpath'));   % this folder
addpath(fullfile(CodeFolder, 'functions'));       % model and methods
addpath(fullfile(CodeFolder, 'scripts'));         % the two examples
addpath(fullfile(CodeFolder, 'verify'));          % verify_against_paper.m
TablesFolder = fullfile(CodeFolder, 'tables');    % output CSV files

% ===== Example 1 (two nodes, four scenarios): Tables 2 and 3
Start = tic;
Results1 = example1_two_node(TablesFolder);
fprintf('Example 1: Tables 2 and 3 written to tables/ (%.1f s)\n', toc(Start));

% ===== Example 2 (six nodes, one scenario): Tables 4 and 5
Start = tic;
Results2 = example2_six_node(TablesFolder);
fprintf('Example 2: Tables 4 and 5 written to tables/ (%.1f s)\n', toc(Start));

% ===== Check every printed value
ReportFile = fullfile(CodeFolder, 'verify', 'verification_report.csv');
Report = verify_against_paper(Results1, Results2, ReportFile);
