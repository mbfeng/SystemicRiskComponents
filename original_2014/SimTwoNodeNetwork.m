%% Two-Nodes Network with up- and down-stream node
Equity = [10; 10];

ExtDebt = [400; 300];

LoanMat = [0  100;  
           0   0];
       
LiabMat = [0   0;  
           100 0];
       
Cash = [10; 10];

RiskyHolding = [300; 400];

RiskyRtn = [0.05	-(71/120)	0.10	-0.025;
            0.05    0.00        -0.175	-0.375];

probs    = [0.88	0.04	0.04    0.04];

% calc_const_leverage_shared(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,3), 'S')
calc_borrowing_provides_cash(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,3), 'AS')
% calc_const_leverage_shared(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,4), 'S')
calc_borrowing_provides_cash(LiabMat, ExtDebt, Cash, RiskyHolding, RiskyRtn(:,4), 'AS')

%% Three-Nodes Network with one lender, one borrower, and one intermediary
% Equity = [50; 50; 50];
% 
% ExtDebt = [1000; 1000; 500];
% 
% LoanMat = [0  500  0;
%            0   0   500;
%            0   0   0];
%        
% Cash = [50; 50; 50];
% 
% RiskyHolding = [500; 1000; 1000];
% 
% RiskyRtn = [0.05  -0.2  0.05  0.05  0.00  0.00  -0.5  -0.2;
%             0.05  0.05  -0.2  0.05  -0.5  0.00  0.00  -0.2;
%             0.05  0.05  0.05  -0.10 0.00  -0.25 -0.1  -0.15];
% 
% probs    = [0.125 0.100 0.100 0.100 0.150 0.150 0.150 0.125];



%% 
% RiskyRtn = [0.1    -0.3   0.1    -0.3   0.1    -0.2   0.1    -0.2;
%             0.05   0.05   0      0      -0.15  -0.15  -0.15  -0.15];
%         
%  % scenario probabilities (question)
% bad = 0.01;
% mid = 0.02;
% good = 1 - bad - 2*mid;
% 
% up = good + mid;
% down = bad + mid;
% 
% probs = [good*good/up good*mid/up mid*good/up mid*mid/up...
%     mid*mid/down mid*bad/down bad*mid/down bad*bad/down];