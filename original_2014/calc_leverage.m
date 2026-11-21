function [alloc] = calc_leverage(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn, Method)
% [alloc] = calc_leverage(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn, Method)
% Cost allocation using transmission and leverage balance sheet scheme:
% === Equity substitutes for debt. 
% === Cash substitutes for internal loans.
% *** Balance sheet size and Risky Holdings are fixed
% *** External and Internal debts scale with lambda
% *** Equity and Cash determined by balance sheet size
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
vecOne = ones(N,1);     % vector of ones, for consistency with the paper

% balance sheet size of the real system
Asset = Cash + RiskyHolding + LiabMat'*vecOne; 

if(strcmp(Method, 'S'))    
    NumSubset = 2^N;         % number of subsets of {1,...,N}
    Subsets_Str = dec2bin(0:NumSubset-1,N); % all N-bit binary strings
    Subsets_Mtx = double(Subsets_Str) - 48;
    % N-bit binary strings in matrix form. Each row represents on string
    
    % Calculate costs for all 2^N subsets of nodes
    Costs = zeros(NumSubset,1); % placeholder for 2^N costs
    for SetID = 1:NumSubset
        lambda_S = Subsets_Mtx(SetID, :)';          % participation vector
        
        ExtDebt_S = ExtDebt .* lambda_S;                    % external debts
        LiabMat_S = bsxfun(@times, lambda_S, LiabMat);      % loan matrix
        Cash_S = Asset - LiabMat_S'*vecOne - RiskyHolding;   % cash holdings

        % calculate cost to external creditors associated with lambda_S
        clearvar_S = calcClearingPayments(LiabMat_S, ExtDebt_S,...
            Cash_S, RiskyHolding, RiskyRtn);
        fStar_S = clearvar_S.PayFrac;
        Costs(SetID) = ExtDebt' * (1 - fStar_S);
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
    
elseif(strcmp(Method, 'AS')) % Solve points of potential continuities
    lambda = 1;     % initial lambda
    lambdaSet = 1;  % initial set of points
    flag = true;    % auxiliary varaible for looping
    
    TotalDebt = ExtDebt + sum(LiabMat,2); % Internal and external debts
    
    while(flag)
        % Calc. clearing payments associated with current lambda
        ExtDebt_i = lambda * ExtDebt;   % lambda is a scaler
        LiabMat_i = lambda * LiabMat;   % lambda is a scaler
        Cash_i = Asset - LiabMat_i'*vecOne - RiskyHolding;
        clearvar = calcClearingPayments(LiabMat_i, ExtDebt_i, ...
            Cash_i, RiskyHolding, RiskyRtn);
        Red = clearvar.RedSet;
        
        w = inf(N,1);   % placeholder for distance between two lambdas
        
        % sensitivity of clearing payments to the scale lambda
        p_prime = zeros(N,1);
        p_prime(Red) = -clearvar.RightDeriv(Red,Red)*(LiabMat(Red,Red))'*ones(sum(Red),1);
        
        % local movements of nodes that may hit borderline
        I_r = (p_prime < TotalDebt) & Red;
        w(I_r) = (lambda*TotalDebt(I_r)-clearvar.ClearingP(I_r))./(TotalDebt(I_r)-p_prime(I_r));
        
        % determine step-size, the minimum of all possible step sizes
        w_min = min(w);
        if(isinf(w_min) || lambda - w_min<=0)
            flag = false;
            lambda = 0;
        else
            lambda = lambda - w_min;
        end
        
        % determine the next lambda
        lambdaSet(end+1) = lambda;
    end
    
    % determine the widths and midpoints of all intervals
    lambdaSet = sort(lambdaSet);
    w = diff(lambdaSet);
    mu = (lambdaSet(1:end-1)+lambdaSet(2:end))/2;
    
    % placeholder for integration (summation) along the "diagonal"
    sumV = zeros(N,1);
    
    % compute the integral via summation (see paper for detail)
    for i = 1 : length(w)
        ExtDebt_i = ExtDebt * mu(i);
        LiabMat_i = LiabMat * mu(i);
        Cash_i = Asset - LiabMat_i'*vecOne - RiskyHolding;
        clearvar = calcClearingPayments(LiabMat_i, ExtDebt_i,...
            Cash_i, RiskyHolding, RiskyRtn);
        Grad = clearvar.RedSet.*(ExtDebt + LiabMat * (-clearvar.Grad_e));
        sumV = sumV + w(i) * Grad;
    end
    
    % cost allocated (see paper for detail)
    alloc = sumV;
    
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
%             % Calculate cost associated with set S
%             ExtDebt_S = ExtDebt .* lambda_S;
%             LoanMat_S = bsxfun(@times, lambda_S', LoanMat);
%             Cash_S = Asset - LoanMat_S*vecOne - RiskyHolding;
%             clearvar_S = calcClearingPayments(LoanMat_S, ExtDebt_S,...
%                 Cash_S, RiskyHolding, RiskyRtn);
%             fStar_S = clearvar_S.PayFrac;
%             c_S = ExtDebt_S' * max(1 - fStar_S, 0);
%             
%             % Calculate cost associated with set S-union-i
%             ExtDebt_Si = ExtDebt .* lambda_Si;
%             LoanMat_Si = bsxfun(@times, lambda_Si', LoanMat);
%             Cash_Si = Asset - LoanMat_Si*vecOne - RiskyHolding;
%             clearvar_Si = calcClearingPayments(LoanMat_Si, ExtDebt_Si,...
%                 Cash_Si, RiskyHolding, RiskyRtn);
%             fStar_Si = clearvar_Si.PayFrac;
%             c_Si = ExtDebt_Si' * max(1 - fStar_Si, 0);
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
%         S = randperm(N);    % current permutation
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
%             % Calculate cost associated with set S
%             ExtDebt_S = ExtDebt .* lambda_S;
%             LoanMat_S = bsxfun(@times, lambda_S', LoanMat);
%             Cash_S = Asset - LoanMat_S*vecOne - RiskyHolding;
%             clearvar_S = calcClearingPayments(LoanMat_S, ExtDebt_S,...
%                 Cash_S, RiskyHolding, RiskyRtn);
%             fStar_S = clearvar_S.PayFrac;
%             c_S = ExtDebt_S' * max(1 - fStar_S, 0);
%             
%             % Calculate cost associated with set S-union-i
%             ExtDebt_Si = ExtDebt .* lambda_Si;
%             LoanMat_Si = bsxfun(@times, lambda_Si', LoanMat);
%             Cash_Si = Asset - LoanMat_Si*vecOne - RiskyHolding;
%             clearvar_Si = calcClearingPayments(LoanMat_Si, ExtDebt_Si,...
%                 Cash_Si, RiskyHolding, RiskyRtn);
%             fStar_Si = clearvar_Si.PayFrac;
%             c_Si = ExtDebt_Si' * max(1 - fStar_Si, 0);
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
