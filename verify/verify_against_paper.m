function Report = verify_against_paper(Results1, Results2, ReportFile)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% verify_against_paper.m                                                      %
% Checks every number of Tables 2-5 and the numbers quoted in the text of     %
% Section 4 against the values printed in the published article (IIE         %
% Transactions 48(6), 2016). The examples are deterministic, so each value    %
% must round to the printed value: |reproduced - printed| <= half a unit in   %
% the last printed digit. One entry of Table 5 is checked against its        %
% corrected value instead (see README, "Difference from the published        %
% article").                                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input(s):
% -- Results1: struct from example1_two_node.m
% -- Results2: struct from example2_six_node.m
% -- ReportFile: CSV file for the report (none written if empty)
% Output(s):
% -- Report: table, one row per printed value, with status 'ok' or
%    'UNEXPECTED'

% ===== Printed values (as text, to know the printed precision)
%-- Table 2: probabilities and asset returns a - 1 (inputs), nodes' losses
% 1 - f* (outputs), all in percent; rows = scenarios
Table2Probability = {'88'; '4'; '4'; '4'};
Table2Returns = {'5' '5' '5'; '-59.17' '10' '-10'; '10' '-2.5' '-62.5'; '-2.5' '-59.17' '27.5'};
Table2Loss = {'0' '0'; '41.875' '0'; '0' '15'; '8.125' '35'};

%-- Table 3: rows in the order of all_allocations.m; columns = nodes 1, 2
Table3 = {'8000' '6000';
          '6750' '7250';
          '6917' '7083';
          '7350' '6650';
          '7740' '6260';
          '6350' '7650';
          '6300' '7700';
          '6600' '7400';
          '6000' '8000';
          '6150' '7850'};

%-- Table 4: size, equity, external debt, cash, risky assets, portfolio
% return (%), payment fraction f*, sensitivity zeta; rows = nodes
Table4 = {'600'  '50' '150' '50'  '500' '-40' '0.723' '0.635';
          '1000' '50' '750' '50'  '750' '10'  '1'     '0';
          '1000' '25' '875' '50'  '350' '-20' '0.951' '0.981';
          '1000' '50' '750' '800' '0'   '0'   '0.994' '0.996';
          '600'  '50' '150' '50'  '500' '-40' '0.723' '0.997';
          '1000' '50' '750' '50'  '550' '10'  '0.994' '0.996'};

%-- Table 5: rows in the order of all_allocations.m; columns = nodes 1-6
Table5 = {'41572'  '0'      '42517' '4286'   '41572'  '4625';
          '54575'  '-2410'  '44273' '0'      '56945'  '-18812';
          '45404'  '0'      '41899' '0'      '50669'  '-3400';
          '42941'  '0'      '42227' '2383'   '45307'  '1713';
          '41739'  '0'      '41878' '4358'   '42656'  '3940';
          '96674'  '-27561' '44571' '-25005' '99221'  '-53327';
          '122619' '-27714' '44575' '-49901' '149783' '-104791';
          '95238'  '0'      '44151' '-49801' '149567' '-104583';
          '150000' '-55429' '45000' '-50000' '150000' '-105000';
          '109574' '-35193' '44918' '-49844' '149726' '-84609'};

%-- Text of Sections 4.1-4.5: stand-alone risks in Example 1 (rows =
% external assets, transmission/leverage, intermediation; columns = node 1,
% node 2, real system), interactions, and quantities of Example 2
TextStandAlone = {'6700' '7200' '14000';    % Section 4.2
                  '6700' '6000' '14000';    % Section 4.3
                  '6700' '8000' '14000'};   % Section 4.4
TextInteraction = {'100'; '1300'; '-700'};  % system - sum of stand-alone risks
TextSolvencyShare = '600';    % Section 4.4: interaction attributed by solvency to node 2
TextSystemCost = '134571';    % Section 4.1, Example 2

% ===== Reproduced values
Item = {};          % description of each check
Printed = {};       % printed value (text)
Reproduced = [];    % reproduced value

for s = 1:4
    Item{end + 1} = sprintf('Table 2, scenario %d, probability (%%)', s); %#ok<AGROW>
    Printed{end + 1} = Table2Probability{s}; %#ok<AGROW>
    Reproduced(end + 1) = 100 * Results1.Probabilities(s); %#ok<AGROW>
    for k = 1:3
        Item{end + 1} = sprintf('Table 2, scenario %d, a%d - 1 (%%)', s, k); %#ok<AGROW>
        Printed{end + 1} = Table2Returns{s, k}; %#ok<AGROW>
        Reproduced(end + 1) = 100 * Results1.AssetReturns(k, s); %#ok<AGROW>
    end
    for i = 1:2
        Item{end + 1} = sprintf('Table 2, scenario %d, 1 - f*_%d (%%)', s, i); %#ok<AGROW>
        Printed{end + 1} = Table2Loss{s, i}; %#ok<AGROW>
        Reproduced(end + 1) = 100 * Results1.NodeLoss(i, s); %#ok<AGROW>
    end
end

for m = 1:10
    for i = 1:2
        Item{end + 1} = sprintf('Table 3, %s (%s), node %d', Results1.MethodNames{m}, ...
            Results1.ValueNames{m}, i); %#ok<AGROW>
        Printed{end + 1} = Table3{m, i}; %#ok<AGROW>
        Reproduced(end + 1) = Results1.Allocations(m, i); %#ok<AGROW>
    end
end

Net = Results2.Network;
Table4Reproduced = [Net.Size, Net.Equity, Net.ExternalDebt, Net.Cash, Net.RiskyAssets, ...
    100 * Results2.PortfolioReturn, Results2.PayFraction, Results2.Zeta];
Table4Columns = {'size', 'equity', 'external debt', 'cash', 'risky assets', ...
    'portfolio return (%)', 'payment fraction f*', 'sensitivity zeta'};
for i = 1:6
    for c = 1:8
        Item{end + 1} = sprintf('Table 4, node %d, %s', i, Table4Columns{c}); %#ok<AGROW>
        Printed{end + 1} = Table4{i, c}; %#ok<AGROW>
        Reproduced(end + 1) = Table4Reproduced(i, c); %#ok<AGROW>
    end
end

for m = 1:10
    for i = 1:6
        Item{end + 1} = sprintf('Table 5, %s (%s), node %d', Results2.MethodNames{m}, ...
            Results2.ValueNames{m}, i); %#ok<AGROW>
        Printed{end + 1} = Table5{m, i}; %#ok<AGROW>
        Reproduced(end + 1) = Results2.Allocations(m, i); %#ok<AGROW>
    end
end

Schemes = {'external assets', 'transmission and leverage', 'intermediation'};
StandAloneColumns = {'stand-alone risk of node 1', 'stand-alone risk of node 2', 'risk of the system'};
for s = 1:3
    for c = 1:3
        Item{end + 1} = sprintf('Text, Example 1, %s: %s', Schemes{s}, StandAloneColumns{c}); %#ok<AGROW>
        Printed{end + 1} = TextStandAlone{s, c}; %#ok<AGROW>
        Reproduced(end + 1) = Results1.StandAlone(s, c); %#ok<AGROW>
    end
    Item{end + 1} = sprintf('Text, Example 1, %s: interaction', Schemes{s}); %#ok<AGROW>
    Printed{end + 1} = TextInteraction{s}; %#ok<AGROW>
    Reproduced(end + 1) = Results1.StandAlone(s, 3) - Results1.StandAlone(s, 1) ...
        - Results1.StandAlone(s, 2); %#ok<AGROW>
end
Item{end + 1} = 'Text, Example 1, interaction attributed to node 2 by solvency';
Printed{end + 1} = TextSolvencyShare;
Reproduced(end + 1) = Results1.StandAlone(3, 2) - Results1.Allocations(8, 2); % 8000 - 7400
Item{end + 1} = 'Text, Example 2, cost of the system';
Printed{end + 1} = TextSystemCost;
Reproduced(end + 1) = Results2.SystemCost;

% ===== Known differences from the printed values (see README, "Difference
% from the published article"): item and the value this code prints
KnownItems = {'Table 5, External assets (Aumann-Shapley), node 5'};
KnownValues = {'50667'};   % printed: 50669 (a breakpoint skipped by the original search)

% ===== Comparison: round to the printed precision
NumChecks = length(Item);
PrintedValue = zeros(NumChecks, 1);
HalfUnit = zeros(NumChecks, 1);     % half a unit in the last printed digit
Status = cell(NumChecks, 1);
for k = 1:NumChecks
    PrintedValue(k) = str2double(Printed{k});
    Decimals = decimals_printed(Printed{k});
    HalfUnit(k) = 0.5 * 10^(-Decimals);
    Known = find(strcmp(KnownItems, Item{k}));
    if isempty(Known)
        Expected = PrintedValue(k);                  % the printed value
    else
        Expected = str2double(KnownValues{Known});   % the corrected value
    end
    % tolerance 1e-9 for values exactly halfway (e.g., 41.875 printed in full)
    Matches = abs(Reproduced(k) - Expected) <= HalfUnit(k) + 1e-9;
    if Matches && isempty(Known)
        Status{k} = 'ok';
    elseif Matches
        Status{k} = 'corrected (see README)';
    else
        Status{k} = 'UNEXPECTED';
    end
end

Report = table(Item', Printed', PrintedValue, Reproduced', HalfUnit, Status, ...
    'VariableNames', {'Item', 'Printed', 'PrintedValue', 'Reproduced', 'HalfUnit', 'Status'});
if ~isempty(ReportFile)
    writetable(Report, ReportFile);
end

NumOk = sum(strcmp(Status, 'ok'));
NumCorrected = sum(strcmp(Status, 'corrected (see README)'));
NumUnexpected = sum(strcmp(Status, 'UNEXPECTED'));
fprintf('verify_against_paper: %d of %d printed values reproduced', NumOk, NumChecks);
fprintf(' (Tables 2-5 and the numbers quoted in Section 4);\n');
fprintf('  %d value(s) differ as documented in the README (corrected).\n', NumCorrected);
if NumUnexpected > 0 || NumCorrected ~= length(KnownItems)
    disp(Report(~strcmp(Status, 'ok'), :));
    error('Some printed values were not reproduced.');
end
end


function Decimals = decimals_printed(Text)
% Number of digits after the decimal point in a printed number (0 if none)
Point = strfind(Text, '.');
if isempty(Point)
    Decimals = 0;
else
    Decimals = length(Text) - Point;
end
end
