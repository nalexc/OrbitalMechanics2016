function [dkep] = GaussPert (~,kep)

global mu_earth ap_tnh

a = kep(1);
e = kep(2);
i = kep(3);
% OM = kep(4);
om = kep(5);
th = kep(6);

b = a*sqrt(1-e^2);
p = b^2/a;
n = sqrt(mu_earth/a^3);
h = n*a*b;
r = p/(1+e*cos(th));
v = sqrt((2*mu_earth)/r-mu_earth/a);
th_star = th+om;

da = (2*a^2*v)/mu_earth*ap_tnh(1);
de = 1/v*(2*(e+cos(th))*ap_tnh(1)-r/a*sin(th)*ap_tnh(2));
di = r*cos(th_star)/h*ap_tnh(3);
dOM = r*sin(th_star)/(h*sin(i))*ap_tnh(3);
dom = 1/(e*v)*(2*sin(th)*ap_tnh(1)+(2*e+r/a*cos(th))*ap_tnh(2))- ...
    (r*sin(th_star)*cos(i))/(h*sin(i))*ap_tnh(3);
dth = h/r^2-1/(e*v)*(2*sin(th)*ap_tnh(1)+(2*e+r/a*cos(th))*ap_tnh(2));

dkep = [da,de,di,dOM,dom,dth]';