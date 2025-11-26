% This file is created for buck converter controller design. 
% by Fulong Li, @Feb 2025
% Sumitomo project
% Copy-rihgt reserved. for project internal use and reference only. 
%
clear; clc;

s = tf('s');
% input voltage: Vg
Vg = 100;
% output voltage:Vo
Vo = 50;
% inductacne: L
L = 2.4e-3;
% output capacitor: C
C = 100e-6;
% load resistance: R
R = 10;
% duty cycle
D = Vo/Vg;

fs = 20e3;
Ts = 1/fs;

% buck converter transfer function:
Gvd = (Vo/D)*(1/(1+s*L/R+s^2*L*C));
Gid = Vg/R*(1+ s*R*C)/(1+s*L/R+s^2*L*C);
Gvi = Gvd/Gid;

% H(s), feedback gain
H = 1;
% Gm(s) PWM transfer function =1/Vm, where Vm is the amplitude or ram
% set to 1 to avoid repeated multiple and devide calcaulations. 
Gm = 1;

% Go(s) = Gvd(s)*Gm(s)*H(s)
figure;
Go = Gvd*Gm*H;
bode (Go);
grid on;
title('Uncompensated Loop Go')

% check Gd0, f0,Q0
Gd0 = Vo/D;
G0_db = 20*log10(Gd0);
f0 = 1/(2*pi*sqrt(L*C));
Q0 = R*sqrt(C/L);
Q0_db = 20*log10(Q0);

%% single loop control design
% % Loop gain.
T1 = Go;
figure;
%[Gm,Pm,Wcg,Wcp] = 
margin(T1);
grid on;
% read the cross-over frequechy and phase margin of uncompenated loop gain.
% fc = ;
Tuo = Gd0;
% grid on

%% controller selection and design. 
% % PD controller
% select crossover frequency based on bode plot
fco = 5e3; %1kHz, 5/20*fs
% choose a reasonable phase margin
phase = 52*pi/180; 
fz = fco*sqrt((1-sin(phase))/(1+sin(phase)));
fp = fco*sqrt((1+sin(phase))/(1-sin(phase)));
Gco = (fco/f0)^2/Tuo*sqrt(fz/fp);
wz = 2*pi*fz;
wp = 2*pi*fp;
Gc_PD = Gco*(1+s/wz)/(1+s/wp);
figure;
bode(Gc_PD);
grid on;
title('PD controller')

figure;
T2 = Gc_PD*Go;
margin(T2);
grid on;
% 
% % PI controller
Gc_inf = 1;
fl = 100;
wl = 2*pi*fl;
Gc_PI = Gc_inf*(1+wl/s);
figure;
bode(Gc_PI);
grid on;
title('PI controller')

Gc_PID =Gc_PI*Gc_PD;
figure;
bode(Gc_PID);
grid on;
title('PID controller')

Gc_PID_disc = c2d(Gc_PID, Ts); % discrete controller.

T3 = Gc_PID*Go;
figure;
margin(T3);
grid on;
