%% Copyright (C) Dr. Fulong Li, Spirit Connect Group.
% email: fulong.li@ieee.og
% This code is for double loop control design of boost converter, also with
% passive feedforward control loop process. 
% Last updated: Jan, 2022

%% step1, parameters of converter
% clear,clc;
    L = 240e-6*2;
    R = 10;
    %C = 470e-6;
    C = 470e-6;
    r = 0;
    fs = 25e3;  
    Ts = 1/fs;
    Vg = 25;
    V = 50;
    D = 1-Vg/V;
    Dprime = 1-D;
    iL = V^2/R/Vg;
    Rv = 0.5;

%% step2, modeling and build tranfer functions
    wzv = R*Dprime^2/L;
    fzv = wzv/(2*pi);
    wzi = 2/(R*C);
    fzi = 1/(pi*R*C);
    wo = Dprime/sqrt(L*C);
    fo = wo/(2*pi);
    Q = Dprime*R*sqrt(C/L);
    
    %%%%%Le = L/(Dprime^2);
    s = tf('s');
    Gvdo = V/Dprime;
    Gido = 2*V/(Dprime^2*R);
    Ggo = 1/Dprime;
    numv = 1-s/wzv;
    numi = 1+s/wzi;
    den = 1+s/(Q*wo)+(s/wo)^2;
    %step2.2,
    Gvd = Gvdo*numv/den;
    Gid = Gido*numi/den;
    Gvg = Ggo*1/den;
    Zout = 1/((1/R)+1/(s*C)+(s*L/Dprime^2));
    GiL = -1/Dprime/den;
    %h1 = bodeplot(Gvd);
    %setoptions(h1,'FreqUnits','Hz','PhaseVisible','off');
    figure(1);
    subplot(2,3,1);
    margin(Gid);   
    title('Gid');
    grid on;

%% step3, start design inner current compensator
    Rf = 0.25;
    Vm = 1;
    % uncompensated closed loop Tiu;
    Tiu = Rf/Vm*Gid;
    Tiuo = Rf/Vm*Gido;
    %hold on;
    %h2 = bodeplot(sys1);
    %setoptions(h2,'FreqUnits','Hz','PhaseVisible','off');
    subplot(2,3,2);
    margin(Tiu);
    title('Tiu');
    grid on;

%% step4 design pi controller Gci for inner loop
    %----(1+wz/s)------
    %-Gcm--------------
    %----(1+s/wp)------
    % 
    fci = fs/10; % 10% of switching frequency
    wci = 2*pi*fci;
    % once choose crossover freq, we need to determine the gain Gcm
    % the asymtotic of Tiu over crossover freq is about:
    %   Rf*V
    %----------*Gim = 1;
    %   Vm*L*wc
    Gim = (L*wci*Vm)/(V*Rf);
    %choose fz and fp
    fzic = fci/2.5;
    fpic = 2.5*fci;
    wzic = 2*pi*fzic;
    wpic = 2*pi*fpic;
    Gci = Gim*(1+wzic/s)/(1+s/wpic);
    % draw bode plot of Gci
    subplot(2,3,3);
    bode(Gci);
    title('Gci');
    grid on;
    %draw in one and see pahse 
    subplot(2,3,4);
    bode(Gci);
    hold on;
    bode(Tiu);
    title('Tiu & Gci');
    grid on;
    % draw compensated Ti
    Ti=Gci*Tiu;
    subplot(2,3,5);
    margin(Ti);
    title('Ti');
    grid on;
    %show margin
    subplot(2,3,6);
    margin(Ti);
    grid on;

%% step5 build outer voltage plant  
    % the double loop effect alters the plant of outer voltage loop
    % now it becomes, Gvc(v is V, C is ic)
    %Gvc~= 1/Rf * Gvd/Gid;
    Gvc = 1/Rf*Gvd/Gid;
    figure(2);
    subplot(2,3,1);
    margin(Gvc);
    title('Gvc');
    grid on;
    H = 0.0075;
    Tvu = H*Gvc;
    subplot(2,3,2);
    margin(Tvu);
    title('Tvu');
    grid on;

%% step6 design pi controller Gcv for outer loop 
    %-----Gcv = Gvm(1+wzvc/s)
    %
    %
    fcv = fci/10;
    wcv = 2*pi*fcv;
    %the asymtotic of Gid over crossover freq is about:
    %       Dprime          1
    %   H----------------------------*Gvm=1
    %       Rf*C*s   2*pi*fcv*RC/2
    Gvm = (wcv*C*Rf)/(Dprime*H);
    
    fzvc = fcv/3;
    wzvc = 2*pi*fzvc;
    Gcv = Gvm*(1+wzvc/s);%*(1+s/(2*pi*10000))^2*(1+s/(2*pi*1000));%*(1+2*pi*10e4/s);
    %
    subplot(2,3,3);
    bode(Gcv);
    title('Gcv');
    grid on;
    %
    subplot(2,3,4);
    bode(Gcv);
    hold on;
    bode(Tvu);
    title('Tvu & Gci');
    grid on;
    % draw compensated Tv
    Tv=Gcv*Tvu;
    subplot(2,3,5);
    margin(Tv);
    title('Tv');
    grid on;
    %show margin
    subplot(2,3,6);
    margin(Tv);
    grid on;

%% ------------------------------------------------------------------------
%% decide impedance


 %impedance evaluation with pure double loop control
  %  K=0; Rv=0;
 %initial double loop output impedance
    %passive quiencent compensation
    fpa = 50;
    wpa = 2*pi*fpa;
    K = L/(Rf*Dprime*R*C);
 %impedance evaluation with droop control
   % K=0;
    
    Gpa = K/(1+wpa/s);
    Gpa_Vol = Gpa+Gvc;
    Tvp = Gcv*Gpa_Vol;
%discrete operation for CCS
Gci_d = c2d(Gci, Ts, 'tustin');
Gcv_d = c2d(Gcv, Ts, 'tustin');
Gpa_d = c2d(Gpa, Ts, 'tustin');

%several plots
figure(3);
nyquist(Gvc);
hold on;
nyquist(Gpa_Vol);
%view trend;
figure(4);
title('Passive Compensation');
%for A = [0, K, 2*K, 3*K,4*K]
%    Gpa = A/(1+wpa/s);
%    Gpa_Vol = Gpa+Gvc;
%    nyquist(Gpa_Vol);
 %   hold on;
%end
%low pass for Rv
fr = 100;
wr = 2*pi*fr;
%impedance evaluation with passive control
  %Rv=0;
Gr = Rv/(1+s/wr);
%
Cprime = 470e-6*1;
%iL = 2;
iL_CPL = 10;
iL_1 = 100;
Kz = 100;
Gcz = Kz*(1-2*pi*250/s);
A = Dprime*R/(2*Rf);
B = A/(A+K);

%-----------------------------------------------------------

 Loop1 = Gci*V/(s*L+r)*(-1);
 Loop2 = -Gcv*Gci*V/(s*L+r)*(1-D)*Gr;%for droop
 Loop3 = -Gcv*Gci*-iL*Gr;% for droop
 Loop4 = -Gpa*Gcv;
 
 LLop = Loop1*Loop4;
 
 P1 = - Gcv*Gci*V/(s*L+r)*(1-D);
 P2 = -(1-D)^2/(s*L+r);
 P3 = -Gcv*Gci*(-iL);
 P4 = -(1-D)/(s*L+r)*(-1)*Gci*(-iL);
 P5 = -s*Cprime;

 Delta1 = 1;
 Delta2 = 1-Loop4;
 Delta3 = 1;
 Delta4 = 1-Loop4;
 Delta5 = 1-Loop1-Loop4+LLop;

 %impedance evaluation with passive & droop control
 Ydroop_passive = -(P1* Delta1+P2*Delta2+P3*Delta3+P4*Delta4+P5*Delta5)/(1-Loop1-Loop2-Loop3-Loop4+LLop);
 Zo = 1/Ydroop_passive;
 
 figure(5);
 bodeplot(Ydroop_passive);
 title('Terminal Impedance Shaping');
 grid on;
 hold on;
 figure(6);
 nyquist(1/Ydroop_passive);
 hold on;
 % now for CPL battery.
 iLprime = 10;
 C_CPL = 0;
 Y_CPL = (Dprime*Gci*iLprime+Dprime^2+s*C_CPL*(s*L-Gci*V))/(s*L-Gci*V);
 Y_CPS = (Dprime*Gci*iLprime+Dprime^2+s*C_CPL*(s*L+Gci*V))/(s*L+Gci*V);
 Zin = 1/Y_CPL;
 figure(7)
 bodeplot(Ydroop_passive);
 hold on
 bodeplot(Y_CPL);
 grid on;
 T_MLG = Zo/Zin;
 figure(8)
 bodeplot(Zo);
 hold on;
 bodeplot(Zin);
 grid on;
 figure(9)
 nyquist(T_MLG);
 hold on;
 nyquist((s-1)/(s+1));
 title('T_M_L_G');
 figure(10)
 bodeplot(Y_CPL);
 grid on;
 hold on;
 bodeplot(Y_CPS);
 title('Terminal Admittance, Y_C_P_L&Y_C_P_S');