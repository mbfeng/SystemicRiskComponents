function [alloc] = calc_const_leverage_borrower(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn, Method)
% NAME TO BE DECIDED!!! Old name is solvency
% Cost allocation using the following balance sheet scheme:
% === External debt substitutes for internal debt
% === Cash substitutes for internal loans
% *** Balance sheet size, Equity, and Risky Holdings scale with lambda
% *** Borrower responsibility: Internal debts scale linearly with lambda
% *** External debt and Cash determined by balance sheet size
%
% Inputs:
%   LiabMat      - N-by-N interbank liability matrix at time 0
%   ExtDebt      - N-by-1 vector of external debt
%   Cash         - N-by-1 vector of cash holding
%   RiskyHolding - N-by-1 vector of risky asset
%   RiskyRtn     - N-by-1 vector of risky asset return
%   Method       - string specifying which method to use:
%                  'AS'      -> Aumann-Shapley value
%
% Outputs:
%   alloc  - cost allocated to nodes

if(~strcmp(Method, 'AS'))
    error('Method must be AS');
end

clearvar = calcClearingPayments(LiabMat, ExtDebt, ...
    Cash, RiskyHolding, RiskyRtn);

N = size(LiabMat,1);

Equity = Cash + RiskyHolding + sum(LiabMat,1)' - ExtDebt - sum(LiabMat,2);

zeta = -clearvar.Grad_e;

alloc = (RiskyHolding .* (-RiskyRtn) - Equity).*zeta;

end