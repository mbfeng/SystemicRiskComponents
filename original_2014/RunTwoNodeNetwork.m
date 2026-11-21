%% Initialization
clc; clear all;         % clear workspace and screen
rng(0, 'v5uniform');    % initialize random number generator

%% Networks to be studied
SimTwoNodeNetwork; % Random network (specify params in sim_random_network.m)

%% Main runs
[NumNodes, NumScen] = size(RiskyRtn);
NumMethod = 10;

Results = zeros(NumNodes, NumMethod, NumScen);  % placeholder for results
MethodNames = {'Loss', 'ExA-S', 'Lvg-S', 'SR-S', ...
    'ExA-AS', 'Lvg-AS', 'SR-AS', 'BR-AS', 'LR-AS', 'BC-AS'};

for scen = 1:NumScen
    SolStruct = calcClearingPayments(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen));
    fprintf('----- The clearing payment and sensitivity analysis are computed.\n');
    
    % External creditors loss
    Results(:, 1, scen) = calc_external_creditor_loss(ExtDebt, SolStruct.PayFrac);
    
    Results(:, 2, scen) = calc_leverage(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'S');
    Results(:, 3, scen) = calc_leverage(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
    
    Results(:, 4, scen) = calc_external_assets(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'S');
    Results(:, 5, scen) = calc_external_assets(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
    
    Results(:, 6, scen) = calc_const_leverage_shared(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'S');
    Results(:, 7, scen) = calc_const_leverage_shared(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
    Results(:, 8, scen) = calc_const_leverage_borrower(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
    Results(:, 9, scen) = calc_const_leverage_lender(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
    Results(:, 10, scen) = calc_borrowing_provides_cash(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
    
end

MeanResults = zeros(NumNodes, NumMethod);
for scen = 1:NumScen
    MeanResults = MeanResults + Results(:,:,scen)*probs(scen);
end

%% 
% [NewNumNodes, NewNumScen] = size(RiskyRtn);
% NewNumMethod = 10;
% 
% NewResults = zeros(NewNumNodes, NewNumMethod, NewNumScen);  % placeholder for results
% NewMethodNames = {'Loss', 'ExA-S', 'Lvg-S', 'SR-S', ...
%     'ExA-AS', 'Lvg-AS', 'SR-AS', 'BR-AS', 'LR-AS', 'BC-AS'};
% 
% for scen = 1:NewNumScen
%     SolStruct = calcClearingPayments(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen));
%     fprintf('----- The clearing payment and sensitivity analysis are computed.\n');
%     
%     % External creditors loss
%     NewResults(:, 1, scen) = calc_external_creditor_loss(ExtDebt, SolStruct.PayFrac);
%     
%     NewResults(:, 2, scen) = calc_leverage(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'S');
% %     NewResults(:, 3, scen) = calc_leverage(LoanMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
% %     
% %     NewResults(:, 4, scen) = calc_external_assets(LoanMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'S');
% %     NewResults(:, 5, scen) = calc_external_assets(LoanMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
% %     
% %     NewResults(:, 6, scen) = calc_const_leverage_shared(LoanMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'S');
% %     NewResults(:, 7, scen) = calc_const_leverage_shared(LoanMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
% %     NewResults(:, 8, scen) = calc_const_leverage_borrower(LoanMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
% %     NewResults(:, 9, scen) = calc_const_leverage_lender(LoanMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
% %     NewResults(:, 10, scen) = calc_borrowing_provides_cash(LoanMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,scen), 'AS');
%     
% end
% 
% NewMeanResults = zeros(NewNumNodes, NewNumMethod);
% for scen = 1:NumScen
%     NewMeanResults = NewMeanResults + NewResults(:,:,scen)*probs(scen);
% end