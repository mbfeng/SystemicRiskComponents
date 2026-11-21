function [alloc] = calc_const_leverage_lender(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn, Method)
% NAME TO BE DECIDED!!! Old name is absorption with method AS
% Cost allocation using absorption balance sheet scheme:
% === External debt substitutes for internal debt
% === Cash substitutes for internal loans
% *** Balance sheet size, Equity, and Risky Holdings scale with lambda
% *** Lender responsibility: Internal loans scale linearly with lambda
% *** External debt and Cash determined by balance sheet size
%
% Inputs:
%   LiabMat      - N-by-N interbank liability matrix at time 0
%   ExtDebt      - N-by-1 vector of external debt
%   Cash         - N-by-1 vector of cash holding
%   RiskyHolding - N-by-1 vector of risky asset
%   RiskyRtn     - N-by-1 vector of risky asset return
%   Method       - string specifying which method to use:
%                  'SExact'  -> Shaley value with exact formula
%                  'SSample' -> Shaley value with random sampling
%                  'AS'      -> Aumann-Shapley value
%
% Outputs:
%   alloc  - cost allocated to nodes
%   stderr - standard error of cost allocated if random sampling is used

if(~strcmp(Method, 'AS'))
    error('Method must be AS');
end

% see paper for details
clearvar = calcClearingPayments(LiabMat, ExtDebt, ...
    Cash, RiskyHolding, RiskyRtn);

N = size(LiabMat,1);    % number of nodes in the system

fStar = clearvar.PayFrac;

alloc = (ExtDebt + sum(LiabMat,2)) .* (1-fStar) - LiabMat' * (1-fStar);
    

