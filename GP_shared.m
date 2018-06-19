%GavinPaul Shared Script
disp('hello')
f1 = 1; %frequency for signal1
f2 = 5;%frequency for signal2
a1 = 2; %amplitude for signal1
a2 = 1; %amplitude for signal2
t = 4; % number of seconds for duration of signals
time=0:.001:t;
tmod_freq = .5;% frequency to use for amplitude modulation
tmod = sin(2*pi*time*tmod_freq); %like a weighting function...need to check that it is 0-1


sig1= a1*sin(2*pi*time*f1); %constant amplitude signal

sig1_amod = tmod.*sig1; % amplitude modulated signal

sig2 = a2*sin(2*pi*time*f2); %constant amplitude signal2
sig2_amod = tmod.*sig2; %amplitude modulated signal 2

%Sig1 vs Sig2 gives power to power modulation

sig3=sig2; %sig3 = constant amplitude signal2

%sig1_amod (or sig1) vs. Sig3 gives phase to phase modulation

mi=10;
mf=f1;
fmodsig = a1*sin(2*pi*f2*time+mi.*sin(2*pi*mf*time)); %phase to phase


amodsig = angle(exp(2*pi*i*time*f1)).*a2.*sin(2*pi*f2*time); %phase to power

%figure; plot(time,sig1_amod); hold on; plot(time,fmodsig,'r')

 figure;
 subplot(6,1,1)
 plot(sig1)
 subplot(6,1,2)
 plot(sig1_amod)
 subplot(6,1,3)%power to power
 plot(sig2_amod)
 subplot(6,1,4)
 plot(sig2) %phase to phase
 subplot(6,1,5)
 plot(fmodsig)%phase to frequency
 subplot(6,1,6)
 plot(amodsig) %phase to amplitude