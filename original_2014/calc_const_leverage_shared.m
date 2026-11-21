function [alloc] = calc_const_leverage_shared(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn, Method)
% NAME TO BE DECIDED!!! Old name is absorption with method S.
% Cost allocation using the following balance sheet scheme:
% === External debt substitutes for internal debt
% === Cash substitutes for internal loans
% *** Balance Sheet Size, Equity, and Risky Holdings scale with lambda
% *** Shared responsibility: Internal debts and loans scale quadratically with lambda
% *** External debt and Cash determined by balance sheet size
%
% Inputs:
%   LiabMat      - N-by-N interbank liability matrix at time 0
%   ExtDebt      - N-by-1 vector of external debt
%   Cash         - N-by-1 vector of cash holding
%   RiskyHolding - N-by-1 vector of risky asset
%   RiskyRtn     - N-by-1 vector of risky asset return
%   Method       - string specifying which method to use:
%                  'S'  -> Shapley value
%                  'AS' -> Aumann-Shapley value
%
% Outputs:
%   alloc  - cost allocated to nodes
%
% NOTES: At the end of this file there are codes for more methods for
% calculating Shapley values:
%  'SExact'  -> Shaley value with exact formula
%  'SSample' -> Shaley value with random sampling

N = size(LiabMat,1);    % number of nodes in the system
alloc = zeros(N,1);     % preallocate memory for final result
IntLoan = sum(LiabMat,1)';   % internal loans
IntDebt = sum(LiabMat,2);  % internal debts

% balance sheet size and equity of the real system
Asset = Cash + RiskyHolding + IntLoan;
Equity = Cash + RiskyHolding + IntLoan - ExtDebt - IntDebt;

if(strcmp(Method, 'S'))
    NumSubset = 2^N;         % number of subsets of {1,...,N}
    Subsets_Str = dec2bin(0:NumSubset-1,N); % all N-bit binary strings
    Subsets_Mtx = double(Subsets_Str) - 48;
    % N-bit binary strings in matrix form. Each row represents on string
    
    % Calculate costs for all 2^N subsets of nodes
    Costs = zeros(NumSubset,1); % placeholder for 2^N costs
    for SetID = 1:NumSubset
        lambda_S = Subsets_Mtx(SetID, :)';          % participation vector
        
        Asset_S = Asset .* lambda_S;
        RiskyAsset_S = RiskyHolding .* lambda_S;
        Equity_S = Equity .* lambda_S;
        LiabMat_S = diag(lambda_S)*LiabMat*diag(lambda_S);
        Cash_S = Asset_S - RiskyAsset_S - sum(LiabMat_S,1)';
        ExtDebt_S = Asset_S - Equity_S - sum(LiabMat_S,2);
            
        % calculate cost to external creditors associated with lambda_S
        clearvar_S = calcClearingPayments(LiabMat_S, ExtDebt_S, ...
                Cash_S, RiskyAsset_S, RiskyRtn);
        fStar_S = clearvar_S.PayFrac;
        Costs(SetID) = ExtDebt_S' * (1 - fStar_S);
    end
    
    % Calculate Shapley value of each node
    for NodeID = 1:N
        S_Idx = find(Subsets_Mtx(:,NodeID) == 0);   % subsets w/o node i
        Si_Idx = S_Idx + 2^(N-NodeID);              % subsets w/ node i
        
        Sum_S = 0; % placeholder for summation
        for Idx = 1:length(S_Idx)
            S_Size = sum(Subsets_Mtx(S_Idx(Idx),:));    % cardinality |S|
            
            % (1/N!) * sum_{i \notin S} (N-|S|-1)!|S|!(c(Si) - c(S))
            Sum_S = Sum_S + factorial(N - S_Size - 1)*factorial(S_Size)*...
                (Costs(Si_Idx(Idx))-Costs(S_Idx(Idx)));
        end
        
        alloc(NodeID) = Sum_S; % divide summation by factorial
    end
    alloc = alloc/factorial(N);
    
elseif(strcmp(Method, 'AS'))
    
    alloc1 = calc_const_leverage_borrower(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn, Method);
    alloc2 = calc_const_leverage_lender(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn, Method);
    
    alloc = 0.5 * (alloc1 + alloc2);
    
else
    error('Wrong Method');
end
end












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extra codes for calculating Shapley values  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if(strcmp(Method, 'SExact'))
%
%     alloc = zeros(N,1);     % preallocate memory for cost allocated
%     All_S = perms(1:N);     % all possible permutations
%     NumPerm = factorial(N); % total number of permutations
%     fprintf('-Applying Shapley value with exact formula.\n')
%     fprintf('-A total of %i permutations will be examined.\n', NumPerm);
%
%     for p = 1 : NumPerm
%         S = All_S(p,:);     % current permutation
%
%         for k = 1 : N
%             i = S(k);
%
%             % Determine the set S and S-union-i
%             lambda_S = zeros(N,1);
%             lambda_Si = zeros(N,1);
%             lambda_S(S(1:k-1)) = 1;
%             lambda_Si(S(1:k)) = 1;
%
%             % balance sheet scheme for set S
%             Asset_S = Asset .* lambda_S;
%             RiskyAsset_S = RiskyHolding .* lambda_S;
%             Equity_S = Equity .* lambda_S;
%             LoanMat_S = diag(lambda_S)*LoanMat*diag(lambda_S);
%             Cash_S = Asset_S - RiskyAsset_S - LoanMat_S*vecOne;
%             ExtDebt_S = Asset_S - Equity_S - LoanMat_S'*vecOne;
%             clearvar_S = calcClearingPayments(LoanMat_S, ExtDebt_S, ...
%                 Cash_S, RiskyAsset_S, RiskyRtn);
%             fStar_S = clearvar_S.PayFrac;
%             c_S = ExtDebt_S' * (1 - fStar_S);
%
%             % balance sheet scheme for set S-union-{i}
%             Asset_Si = Asset .* lambda_Si;
%             RiskyAsset_Si = RiskyHolding .* lambda_Si;
%             Equity_Si = Equity .* lambda_Si;
%             LoanMat_Si = diag(lambda_Si)*LoanMat*diag(lambda_Si);
%             Cash_Si = Asset_Si - RiskyAsset_Si - LoanMat_Si*vecOne;
%             ExtDebt_Si = Asset_Si - Equity_Si - LoanMat_Si'*vecOne;
%             clearvar_Si = calcClearingPayments(LoanMat_Si, ExtDebt_Si, ...
%                 Cash_Si, RiskyAsset_Si, RiskyRtn);
%             fStar_Si = clearvar_Si.PayFrac;
%             c_Si = ExtDebt_Si' * (1 - fStar_Si);
%
%             % Calculate the contribution of {i} in the current permutation
%             Contribution = c_Si - c_S;
%             alloc(i) = alloc(i) + Contribution;
%         end
%
%         if(mod(p, 10000)==0) % Display message to show progress
%             fprintf('%d permutations have been examined.\n', p);
%         end
%     end
%
%     % cost allocation equals to the average contribution
%     alloc = alloc./NumPerm;
%
% elseif(strcmp(Method, 'SSample'))
%     maxIter = 1e3;  % maximum number of permutation sampled
%
%     alloc = zeros(N,1);         % placeholder for cost allocation
%     alloc_sqsum = zeros(N,1);   % auxiliary variable for stderr calc.
%
%     fprintf('-Applying Shapley value with sampling method.\n')
%     fprintf('-A total of %i sample permutation will be examined.\n', maxIter);
%
%     for p = 1 : maxIter
%         S = randperm(N); % current permutation
%
%         for k = 1 : N
%             i = S(k);
%
%             % Determine the set S and S-union-i
%             lambda_S = zeros(N,1);
%             lambda_Si = zeros(N,1);
%             lambda_S(S(1:k-1)) = 1;
%             lambda_Si(S(1:k)) = 1;
%
%             % balance sheet scheme for set S
%             Asset_S = Asset .* lambda_S;
%             RiskyAsset_S = RiskyHolding .* lambda_S;
%             Equity_S = Equity .* lambda_S;
%             LoanMat_S = diag(lambda_S)*LoanMat*diag(lambda_S);
%             Cash_S = Asset_S - RiskyAsset_S - LoanMat_S*vecOne;
%             ExtDebt_S = Asset_S - Equity_S - LoanMat_S'*vecOne;
%             clearvar_S = calcClearingPayments(LoanMat_S, ExtDebt_S, ...
%                 Cash_S, RiskyAsset_S, RiskyRtn);
%             fStar_S = clearvar_S.PayFrac;
%             c_S = ExtDebt_S' * (1 - fStar_S);
%
%             % balance sheet scheme for set S-union-{i}
%             Asset_Si = Asset .* lambda_Si;
%             RiskyAsset_Si = RiskyHolding .* lambda_Si;
%             Equity_Si = Equity .* lambda_Si;
%             LoanMat_Si = diag(lambda_Si)*LoanMat*diag(lambda_Si);
%             Cash_Si = Asset_Si - RiskyAsset_Si - LoanMat_Si*vecOne;
%             ExtDebt_Si = Asset_Si - Equity_Si - LoanMat_Si'*vecOne;
%             clearvar_Si = calcClearingPayments(LoanMat_Si, ExtDebt_Si, ...
%                 Cash_Si, RiskyAsset_Si, RiskyRtn);
%             fStar_Si = clearvar_Si.PayFrac;
%             c_Si = ExtDebt_Si' * (1 - fStar_Si);
%
%             % Calculate the contribution of {i} in the current permutation
%             Contribution = c_Si - c_S;
%             alloc(i) = alloc(i) + Contribution;
%             alloc_sqsum(i) = alloc_sqsum(i) + Contribution^2;
%         end
%
%         if(mod(p, 100)==0)
%             display(sprintf('%d samples have been simulated', p));
%         end
%     end
%
%     % calculate standard error
%     var = (alloc_sqsum - alloc.^2/(maxIter))/(maxIter-1); % sample variance
%     stderr =  sqrt(var);    % sample standard error
%
%     % cost allocation equals to the average contribution
%     alloc = alloc / maxIter;