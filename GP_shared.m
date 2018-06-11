%GavinPaul Shared Script
disp('hello')
f1 = 4; %frequency for sig1
f2 = 10;
a1 = 2; %amplitude for sig1
a2 = 1;
t = 4; % number of seconds for duration of signals
tmod_freq = .2;% frequency to use for amplitude modulation
tmod = sin(2*pi*time*tmod_freq); %like a weighting function...need to check that it is 0-1
time=0:.01:t;

sig1= a1*sin(2*pi*time*f1); %constant amplitude signal
sig1_amod = tmod.*sig1; % amplitude modulated signal

sig2 = a2*sin(2*pi*time*f2); %constant amplitude signal2
sig2_amod = tmod.*sig2;

%Sig1 vs Sig2 gives power to power modulation

sig3=sig2; %sig3 = constant amplitude signal2

%sig1 vs. Sig3 gives phase to phase modulation


