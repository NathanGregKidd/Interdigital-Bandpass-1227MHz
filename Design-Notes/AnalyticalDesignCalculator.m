% =========================================================================
% Author:    Nathan Kidd
% Date:      2025-09-09
%
% File:      interdigital_filter_design.m
% Purpose:   This program calculates the key parameters of a
%            5-pole Chebyshev interdigital bandpass filter
%            centered at 1227.6 MHz, including fractional bandwidth,
%            coupling coefficients, and external quality factors.
%            Outputs are intended for use in layout and EM simulation.
%
%
% License:
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% =========================================================================


%% SPECS $$
f0 = 1227.6E6 % L2 center frequency
bandwidth = 20E6 % bandwidth = 20 megahertz
% filter type = Chebyshev
pb_ripple = 0.1 % dB
order = 5 % filter order



%% Chebyshev filter design %%
% G values correlating to order 5 pb_ripple 0.1
if (pb_ripple == 0.1 && order == 5) % ensure that the program doesn't use these values if the order or ripple is changed in the specs
  g1 = 0.756;
  g2 = 1.330;
  g3 = 1;
  g4 = 1.33;
  g5 = 0.756;
  g = [g1, g2, g3, g4, g5]
else % more combinations can be specified with "ifelse"
  assert("g values not specified for specified ripple and order")
endif


%% ripple factor
epsilon = sqrt(10^(pb_ripple/10) - 1)

%% Fractional bandwidth
FBW = bandwidth / f0

%% coupling coefficients
k = zeros(1, size(g)(2) - 1);
for i = 1:size(k)(2)
  k(i) = FBW/sqrt(g(i)*g(i+1));
endfor
k







