clear all; clc;
rng(0, 'v5uniform');    % initialize random number generator

%% Two-Nodes Network with up- and down-stream node
% Equity = 100*[1; 1; 1; 2; 1; 0.5];
% 
% ExtDebt = 100*[14;9;9;13;14;14.5];
% 
% LoanMat = 100*[0    10   0    0    0    0;  
%                0    0    10   0    0    0;
%                0    0    0    5    0    0;
%                0    0    0    0    5    0;
%                0    0    0    0    0    5;
%                5    0    0    0    0    0];
%        
% Cash = 100*[1; 1; 1; 2; 0; 1];
% 
% RiskyHolding = 100*[9; 9; 14; 13; 15; 14;];

%% 
% Equity = [100;600;350;350;500;1100];
% 
% ExtDebt = [2000;1500;3500;2000;3100;1000];
% 
% LoanMat = [0     2000  0     0     0     0;  
%            0     0     250   0     0     250;
%            0     0     0     0     0     1750;
%            0     0     0     0     250   0;
%            2000  0     0     0     0     0;
%            0     0     0     1750  250   0];
%        
% Cash = [100;500;350;350;600;1100];
% 
% RiskyHolding = [2000;3100;2000;3500;1500;1000];
% 
% Liability = Equity + ExtDebt + sum(LoanMat,1)'
% 
% Asset = Cash + RiskyHolding + sum(LoanMat, 2)

%% 
% Equity = 100*[12;7;27;22;7;7];
% 
% ExtDebt = 100*[40;45;35;40;20;20];
% 
% LoanMat = 100* [0     30    0     0     0     0;  
%                 0     0     20    0     0     35;
%                 0     0     0     0     0     20;
%                 0     0     0     0     20    0;
%                 30    0     0     0     0     0;
%                 0     0     0     20    35    0];
%        
% Cash = 100*[12;7;2;22;7;27];
% 
% RiskyHolding = 100*[40;20;60;40;45;0];
% 
% Liability = Equity + ExtDebt + sum(LoanMat,1)'
% 
% Asset = Cash + RiskyHolding + sum(LoanMat, 2)

%%
Equity = 10*[5;5;2.5;5;5;5];

ExtDebt = 10*[15;75;87.5;75;15;75];

LoanMat = 10 * [0     0     5     0     0     0;  
                20    0     0     0     0     0;
                0     20    0     20    0     20;
                0     0     0     0     20    0;
                0     0     5     0     0     0;
                20    0     0     0     20    0];
       
Cash = 10*[5;5;5;80;5;5];

RiskyHolding = 10*[50;75;35;0;50;55];

Liability = Equity + ExtDebt + sum(LoanMat,1)'

Asset = Cash + RiskyHolding + sum(LoanMat, 2)


%% 
NumNodes = 6;
NumMethod = 10;

Results = zeros(NumNodes, NumMethod);  % placeholder for results
MethodNames = {'Loss', 'ExA-S', 'Lvg-S', 'SR-S', ...
    'ExA-AS', 'Lvg-AS', 'SR-AS', 'BR-AS', 'LR-AS', 'BC-AS'};

SavedResults = zeros(NumNodes, NumMethod, 0);
SavedRtn = zeros(NumNodes, 0);

for scen = 1:1
%     RiskyRtn = (unidrnd(79,6,1)-40)*2.5/100;
    RiskyRtn=[-0.4;0.1;-0.2;0;-0.4;0.1];
    
    SolStruct = calcClearingPayments(LoanMat', ExtDebt, Cash, RiskyHolding, RiskyRtn);
    fprintf('----- The clearing payment and sensitivity analysis are computed.\n');
    
    % External creditors loss
    Results(:, 1) = calc_external_creditor_loss(ExtDebt, SolStruct.PayFrac);
    
    Results(:, 2) = calc_leverage(LoanMat', ExtDebt, Cash, RiskyHolding, RiskyRtn, 'S');
    Results(:, 3) = calc_leverage(LoanMat', ExtDebt, Cash, RiskyHolding, RiskyRtn, 'AS');
    
    Results(:, 4) = calc_external_assets(LoanMat', ExtDebt, Cash, RiskyHolding, RiskyRtn, 'S');
    Results(:, 5) = calc_external_assets(LoanMat', ExtDebt, Cash, RiskyHolding, RiskyRtn, 'AS');
    
    Results(:, 6) = calc_const_leverage_shared(LoanMat', ExtDebt, Cash, RiskyHolding, RiskyRtn, 'S');
    Results(:, 7) = calc_const_leverage_shared(LoanMat', ExtDebt, Cash, RiskyHolding, RiskyRtn, 'AS');
    Results(:, 8) = calc_const_leverage_borrower(LoanMat', ExtDebt, Cash, RiskyHolding, RiskyRtn, 'AS');
    Results(:, 9) = calc_const_leverage_lender(LoanMat', ExtDebt, Cash, RiskyHolding, RiskyRtn, 'AS');
    Results(:, 10) = calc_borrowing_provides_cash(LoanMat', ExtDebt, Cash, RiskyHolding, RiskyRtn, 'AS');
    
%     cond11 = ( max(Results(:, 5)) > 0 && min(Results(:, 5)) < 0);
%     cond12 = ( max(Results(:, 7)) > 0 && min(Results(:, 7)) < 0);
%     cond13 = 1;
%     cond14 = 1;
%     
%     cond21 = ( max(Results(6, :)) > 0 && min(Results(6, :)) < 0);
%     cond22 = 1;
%     cond23 = 1;
%     cond24 = 1;
%     
%     cond1 = (cond11 && cond12 && cond13 && cond14);
%     cond2 = (cond21 && cond22 && cond23 && cond24);
%     
% %     cond4 = ( Results(5, 1) == 0);
% %     cond5 = ( Results(6, 1) > 0);
%     
%     
%     RowNorm = sqrt(sum(abs(Results).^2,2));
% %     cond2 = (min(RowNorm) > 0);
% %     
% %     cond3 = max(max(Results)) < 950;
% %     
% %     cond4 = (Results(3,8) > Results(3,9) && Results(1,8) < Results(1,9));
% %     cond5 = (Results(5,5) > Results(5,6) && Results(6,5) < Results(6,6));
%     
%     ColNorm = sqrt(sum(abs(Results).^2,1));
% %     if (length(ColNorm) == length(unique(ColNorm)) && cond1 && cond2 && cond3);
%     if (length(ColNorm) == length(unique(ColNorm)) && cond1 && cond2);
%         SavedResults(:,:,end+1) = Results;
%         SavedRtn(:,end+1) = RiskyRtn;
%     end
    
end