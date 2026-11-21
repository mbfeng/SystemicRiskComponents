function [alloc] = calc_borrowing_provides_cash(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn, Method)
% NAME TO BE DECIDED!!! Old name is funding
% Cost allocation using solvency balance sheet scheme:
% === Borrowing provides cash.
% *** Equity, External Debts, and Risky Holdings scale with lambda
% *** Lender responsibility: Internal Loans scale linearly with lambda
% *** Balance sheet size and cash determined by accounting equation
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

clearvar = calcClearingPayments(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn);

fStar = clearvar.PayFrac;
zeta = -clearvar.Grad_e;

N = size(LiabMat,1);
vecOne = ones(N,1);

alloc = ExtDebt .* (1-fStar) + (LiabMat*vecOne).*zeta.*(1-fStar) - LiabMat'*(zeta.*(1-fStar));