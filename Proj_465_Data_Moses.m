% Moses Mccabe   Design Project    EECE465
%These are the plots from the     arduino data
%%
clear;clc;close all % close and clear everything
%%
file = xlsread('data1.xlsx');
T1 = file(:,1);
T1 = T1 + 10;                  % time vector
dataRaw1 = file(:,2);   
dataRaw  = abs(dataRaw1-mean(dataRaw1)); % Raw data
dataFilter = file(:,3);   % filter Data
%% Plot the Sensor Data

Fs = 9600;       % sampling frequency
len = length(dataRaw); % Length of Raw dat
% plot sensor data
figure(1);
subplot(2,1,1)
plot(dataRaw); title('Raw Data')
subplot(2,1,2)
plot(dataFilter); title('filter data');
ylim([0 3]);
%% Use Fourier transforms to find the frequency components of a signal buried in noise

ff = fft(dataRaw); % Fourier transform of the signal
p2 = abs(ff/len); % two-sided spectrum
figure(2);
subplot(2,1,1)
plot(p2),grid, title('Two-Sided Amplitude Spectrum')
xlabel('f (Hz)')
ylabel('|P1(f)|')
%%
 p1 = p2(1:len/2+1); % single-sided spectrum
%%
% single-sided spectrum base on even-valued signal length 
p1(2:end-1) = 2*p1(2:end-1); 


f = linspace(0,4.799,32763); % Define the frequency domain
                             % 4.799 = Fs*(0:(L/2))/L;

subplot(2,1,2)
plot(f,p1), grid, title('Single-Sided Amplitude Spectrum')
xlabel('f (Hz)')
ylabel('|P1(f)|')
%% set pass and stopband base on single-sided spectrum
%%
% 
%  EMG signal is known to shows at 50-150Hz. 
%  Stop and Passband is between 0 - 1.
%

wn = Fs/2;       % cut off frequency
wp = 7.13e-3;      % passband = 2pi(
ws = 0.24;        % stopband
%% Butterworth filter

ds = 0.01;
Const= 0.9;

% Analog Filter
T = 1;
Omega_p = 2/T * tan(wp/2);
Omega_s = 2/T * tan(ws/2);
delta1 = 1 - Const^2;
delta2 = ds^(2);

% Order of Butterworth filter
N = (log10( (1 / (1 - delta1) - 1) / (1 / delta2 - 1)) / log10(Omega_p / Omega_s))/2;
N = ceil(N) % round towards plus infinity

Omega_c = Omega_p / (1 / (1 - delta1) - 1)^(1/(2*N));
k = 0:N-1;
Sk = Omega_c * exp(j*pi*((2*k+1)/2/N + 1/2));
Poles = (1 + (Sk*T/2))./(1 - (Sk*T/2));
Zeros = -ones(1,N);
Zeros = Zeros';
Poles = Poles';

figure(3);
zplane(Zeros, Poles);
title(sprintf('%dth Oder Butterworth LPF', N));

[num, den] = zp2tf(Zeros, Poles, 1); % return the zeros and poles of a TF
%{ 
    [H, W] = freqz(B,A,N)
return the n-point complex freq response
vector H and the N-point freq vector W in rad/samp of the filter.
%}
[H, W] = freqz(num, den, 2048);
 rescale = abs(H(1)); % the abs of the max value of the passband = 1
[num, den] = zp2tf(Zeros, Poles, 1/rescale);
[H, W] = freqz(num, den, 2048);
H_corner = freqz(num, den, [wp ws]);
H_corner = abs(H_corner)

figure(4);
plot(W, abs(H));
title(sprintf('%dth Oder Butterworth LPF', N));
xlabel('\omega');
ylabel('|H(w)|');

figure(5);
plot(W, 20*log10(abs(H)+eps));
title(sprintf('%dth Oder Butterworth LPF', N));
xlabel('\omega');
ylabel('|H(w)|:dB');

v = axis;
axis([v(1:2) -100 v(4)]);
[h,t] = impz(num,den,512);

figure(6);
plot(t, h);
title(sprintf('%dth Oder Butterworth LPF, impulse response', N));
xlabel('t');
ylabel('h(t)');
%% filter and plot Raw data

figure(7);
F = filter(num,den,dataRaw); % Filter signal
subplot(3,1,1)
plot(T1,F),grid,title('Filter Signal') % plot filter data
subplot(3,1,2)
plot(T1,dataRaw), title('Raw data')   % plot Raw data