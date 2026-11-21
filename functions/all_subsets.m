function Subsets = all_subsets(NumNodes)
% All 2^n subsets of the nodes {1, ..., n} as indicator vectors
% Input(s):
% -- NumNodes: n
% Output(s):
% -- Subsets: 2^n x n matrix of 0/1; row k is the binary representation of
%    k - 1 with node 1 as the most significant bit, so row 1 is the empty set
%    and row 2^n is the full set (the ordering shapley_value.m relies on)

Strings = dec2bin(0:2^NumNodes - 1, NumNodes); % 2^n x n char of '0'/'1'
Subsets = double(Strings == '1');              % convert to 0/1 numbers
end
