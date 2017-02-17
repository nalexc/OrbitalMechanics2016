%% ASSIGNMENT 2 - INTERPLANETARY FLYBY
%  Planetes : Mars, Saturn, Neptune
%  (C) Collogrosso Alfonso, Cuzzocrea Francescodario, Lui Benedetto - POLIMI SPACE AGENCY
%  WEB : https://github.com/fcuzzocrea/OrbitalMechanics2016

clear
close all
clc

% File for saving datas
if exist(fullfile(cd, 'results_flyby.txt'), 'file') == 2
    delete(fullfile(cd, 'results_flyby.txt'))
end
filename = 'results_flyby.txt';
fileID = fopen(filename,'w+');
fprintf(fileID,'[ASSIGNMENT 2 : INTERPLANETARY FLYBY]\n');
fclose(fileID);

date =  [2016 1 1 12 0 0];
date = date2mjd2000(date);

%% TIMES MATRIX COMPUTATION

starting_departure_time = [2016 1 1 12 0 0];
final_departure_time = [2055 1 1 12 0 0];
fileID = fopen(filename,'a+');
fprintf(fileID,'[LOG] Mission Window : [%d %d %d %d %d %d] - [%d %d %d %d %d %d]\n',starting_departure_time,final_departure_time);
fclose(fileID);

% Conversion of departure dates from Gregorian calendar
% to modified Julian Day 2000.
date1_departure = date2mjd2000(starting_departure_time);
date2_departure = date2mjd2000(final_departure_time);

% Time of departure window vectors in days and seconds.
% One departure per month
t_dep = date1_departure : 100 : date2_departure ;
t_dep_sec = t_dep*86400;


% First and last arrival dates.
starting_arrival_time = [2016 1 1 12 0 0];
final_arrival_time = [2055 1 1 12 0 0];

% Conversion of arrival dates from Gregorian calendar
% to modified Julian Day 2000.
date1_arrival = date2mjd2000(starting_arrival_time);
date2_arrival = date2mjd2000(final_arrival_time);

% Time of arrival window vectors in days and seconds.
% One arrival per month
t_arr = date1_arrival: 100 : date2_arrival ;
t_arr_sec = t_arr*86400;

% Time of fligth computation. 
TOF_matrix = tof_calculator (t_dep,t_arr);
for q = 1: numel(TOF_matrix)
    if TOF_matrix(q) <= 0
        TOF_matrix(q) = nan;
    end
end

%% DEFINE ORBITS

% Generic for plotting
ibody_mars = 4;
[kep_mars,ksun] = uplanet(date, ibody_mars);
[rx_mars, ry_mars, rz_mars, vx_mars, vy_mars, vz_mars] = int_orb_eq(kep_mars,ksun);

ibody_saturn = 6;
[kep_saturn,ksun] = uplanet(date, ibody_saturn);
[rx_saturn, ry_saturn, rz_saturn, vx_saturn, vy_saturn, vz_saturn] = int_orb_eq(kep_saturn,ksun);

ibody_neptune = 8;
[kep_neptune,ksun] = uplanet(date, ibody_neptune);
[rx_neptune, ry_neptune, rz_neptune, vx_neptune, vy_neptune, vz_neptune] = int_orb_eq(kep_neptune,ksun);

% From ephemeris compute position and velocity for the entire window
parfor i = 1 : length(t_dep)
    [kep_dep_vect_mars(i,:),~] = uplanet(t_dep(i),ibody_mars);
    [r_dep_vect_mars(i,:),v_dep_vect_mars(i,:)] = kep2car(kep_dep_vect_mars(i,:),ksun);
end

parfor i = 1 : length(t_dep)
    [kep_dep_vect_saturn(i,:),~] = uplanet(t_dep(i),ibody_saturn);
    [r_dep_vect_saturn(i,:),v_dep_vect_saturn(i,:)] = kep2car(kep_dep_vect_saturn(i,:),ksun); 
end

parfor i = 1 : length(t_dep)
    [kep_dep_vect_neptune(i,:),~] = uplanet(t_dep(i),ibody_neptune);
    [r_dep_vect_neptune(i,:),v_dep_vect_neptune(i,:)] = kep2car(kep_dep_vect_neptune(i,:),ksun);
end

%% MAIN ROUTINE

% Preallocation
Dv_matrix_1 = zeros(size(t_dep));
Dv_matrix_2 = zeros(size(t_dep));
v_inf_matrix_1 = zeros(size(t_dep));
v_inf_matrix_2 = zeros(size(t_dep));
DV_Tensor = zeros(length(t_dep),length(t_dep),length(t_dep));

% Computation of the 3D-Tensor of deltav with 3 nested for cycles
for i = 1:length(t_dep)
    
    r_mars = r_dep_vect_mars(i,:);
    v_mars = v_dep_vect_mars(i,:);
    
    for j = 1:length(t_dep)
        
        tof_1 = TOF_matrix(i,j)*86400;
        
        if tof_1 > 0
            r_saturn = r_dep_vect_saturn(j,:);
            v_saturn = v_dep_vect_saturn(j,:);
            [~,~,~,~,VI_mars,VF_saturn,~,~] = lambertMR(r_mars,r_saturn,tof_1,ksun);
            dv1_mars = norm(VI_mars - v_mars);
            dv2_saturn = norm(v_saturn - VF_saturn);
            Dv_matrix_1(i,j) = abs(dv1_mars) + abs(dv2_saturn);
            v_inf_matrix_1(i,j) = dv1_mars;
            
            for k = 1:length(t_dep)
                
                tof_2 = TOF_matrix(j,k)*86400;
                
                if tof_2 > 0
                    r_neptune = r_dep_vect_neptune(k,:);
                    v_neptune = v_dep_vect_neptune(k,:);
                    [~,~,~,~,VI_saturn,VF_neptune,~,~] = lambertMR(r_saturn,r_neptune,tof_2,ksun);
                    dv1_saturn = norm(VI_saturn - v_saturn);
                    dv2_neptune = norm(v_neptune - VF_neptune);
                    Dv_matrix_2(j,k) = abs(dv1_saturn) + abs(dv2_neptune);
                    v_inf_matrix_2(j,k) = dv1_saturn;
                                       
                    dv_ga = abs(dv1_saturn - dv2_saturn);
                                     
                    DV_Tensor(i,j,k) = Dv_matrix_1(i,j) + dv_ga + Dv_matrix_2(j,k);
                    
                else
                    Dv_matrix_2(j,k) = nan;
                    v_inf_matrix_2(j,k) = nan;
                    DV_Tensor(i,j,k) = nan;
                end
            end
        else
            Dv_matrix_1(i,j) = nan;
            v_inf_matrix_1(i,j) = nan;
            DV_Tensor(i,j,:) = nan;
        end
    end    
end

% This is done due to fact that first row of output matrix is zeros
Dv_matrix_2(1,:) = nan;
v_inf_matrix_2(1,:) = nan;

% Find the minimum DV
DV_MIN = min(min(min(DV_Tensor)));
DV_MAX = max(max(max(DV_Tensor)));
[row,column,depth] = ind2sub(size(DV_Tensor),find(DV_Tensor == DV_MIN));
fileID = fopen(filename,'a+');
fprintf(fileID,'[LOG] DELTAV MIN %f: \n',DV_MIN);
fclose(fileID);

% Find best arcs
r1_arc = r_dep_vect_mars(row,:);
r2_arc = r_dep_vect_saturn(column,:);
r3_arc = r_dep_vect_neptune(depth,:);

% Find correspondent TOFs
Dv_min_TOF_1 = (TOF_matrix(row,column)*86400);
Dv_min_TOF_2 = (TOF_matrix(column,depth)*86400);

[~,~,~,~,VI_arc1,VF_arc1,~,~] = lambertMR(r1_arc,r2_arc,Dv_min_TOF_1,ksun);
[~,~,~,~,VI_arc2,VF_arc2,~,~] = lambertMR(r2_arc,r3_arc,Dv_min_TOF_2,ksun);

[rx_arc_1, ry_arc_1, rz_arc_1, vx_arc_1, vy_arc_1, vz_arc_1] = intARC_lamb(r1_arc,...
    VI_arc1,ksun,Dv_min_TOF_1,86400);

[rx_arc_2, ry_arc_2, rz_arc_2, vx_arc_2, vy_arc_2, vz_arc_2] = intARC_lamb(r2_arc,...
    VI_arc2,ksun,Dv_min_TOF_2,86400);

% V infinity 
v_saturn = v_dep_vect_saturn(column,:);

v_inf_min = (VF_arc1 - v_saturn );
v_inf_plus = (VI_arc2 - v_saturn);

%% FLYBY

if norm(v_inf_min) - norm(v_inf_plus) == 0
    disp('Powered gravity assist is not needed')
end

delta = acos(dot(v_inf_min,v_inf_plus)/(norm(v_inf_min)*norm(v_inf_plus)));
ksaturn = astroConstants(16);
f = @(r_p) delta - asin(1/(1+(r_p*norm(v_inf_min)^2/ksaturn))) - asin(1/(1+(r_p*norm(v_inf_plus)^2/ksaturn)));
r_p = fzero(f,700000);
fileID = fopen(filename,'a+');
fprintf(fileID,'[LOG] Pericenter Radius of Hyperbola %f: \n',r_p);
fclose(fileID);

% Entering Hyperbola 
e_min = 1 + (r_p*norm(v_inf_min)^2)/ksaturn;
delta_min = 2*(1/e_min);
DELTA_min = r_p*sqrt(1 + 2*(ksaturn/(r_p*norm(v_inf_min)^2)));
theta_inf_min = acos(-1/e_min);
beta_min = acos(1/e_min);
a_min = DELTA_min /(e_min^2 -1);
b_min = a_min*(sqrt(e_min^2 -1));
h_min = sqrt(ksaturn*a_min*(e_min^2 -1));

% Exiting Hyperbola
e_plus = 1 + (r_p*norm(v_inf_plus)^2)/ksaturn;
delta_plus = 2*(1/e_plus);
DELTA_plus = r_p*sqrt(1 + 2*(ksaturn/(r_p*norm(v_inf_plus)^2)));
theta_inf_plus = acos(-1/e_plus);
beta_plus = acos(1/e_plus);
a_plus = DELTA_plus /(e_plus^2 -1);
h_plus = sqrt(ksaturn*a_plus*(e_plus^2 -1));
b_plus = a_plus*(sqrt(e_plus^2 -1));

%DeltaV Pericenter 
vp_min = (DELTA_min*norm(v_inf_min))/(r_p);
vp_plus = (DELTA_plus*norm(v_inf_plus))/(r_p);

% DeltaV Flyby
DELTA_FLYBY = norm(v_inf_plus - v_inf_min);
DELTA_VP = abs(vp_plus - vp_min);
fileID = fopen(filename,'a+');
fprintf(fileID,'[LOG] DeltaV to give %f : \n',DELTA_VP);
fclose(fileID);

% SOI Data
r_soi_saturn = astroConstants(2)*59.879*((astroConstants(16)/astroConstants(1))/(astroConstants(4)/astroConstants(1)))^(2/5);
fileID = fopen(filename,'a+');
fprintf(fileID,'[LOG] Saturn SOI radius %f : \n',r_soi_saturn);
fclose(fileID);

theta_SOI_min = acos((h_min^2/(ksaturn*r_soi_saturn*e_min))-1/e_min);
theta_min = -theta_SOI_min:0.01:0;
theta_min = [theta_min 0];
x_hyp_min = -a_min*((e_min+cos(theta_min))./(1+e_min*cos(theta_min)))+a_min+r_p;
y_hyp_min = b_min*((sqrt(e_min)^2*sin(theta_min))./(1+e_min*cos(theta_min)));

theta_SOI_plus = acos((h_plus^2/(ksaturn*r_soi_saturn*e_plus))-1/e_plus);
theta_plus = 0:0.01:theta_SOI_plus;
theta_plus = [theta_plus theta_SOI_plus];
x_hyp_plus = -a_plus*((e_plus+cos(theta_plus))./(1+e_plus*cos(theta_plus)))+a_plus+r_p;
y_hyp_plus = b_plus*((sqrt(e_plus)^2*sin(theta_plus))./(1+e_plus*cos(theta_plus)));


% Flyby Time
F_min = acosh((cos(theta_SOI_min*2) + e_min)/(1 + e_min*cos(theta_SOI_min*2)));
dt_min = sqrt(a_min^3/ksaturn)*(e_min*sinh(F_min)-F_min);
F_plus = acosh((cos(theta_SOI_plus*2) + e_plus)/(1 + e_plus*cos(theta_SOI_plus*2)));
dt_plus = sqrt(a_plus^3/ksaturn)*(e_plus*sinh(F_plus)-F_plus);
dt_tot = dt_min+dt_plus;
dt_tot_days = dt_tot*1.1574e-5;
fileID = fopen(filename,'a+');
fprintf(fileID,'[LOG] Flyby time %f : \n days',dt_tot_days);
fclose(fileID);

% FlyBy altitude from Saturn
altitude = r_p-astroConstants(26);

%% SATURNOCENTRIC FRAME PLOT

% Rotation matrix : heliocentric -> saturnocentric
[kep_saturn,ksun] = uplanet(t_dep(column), ibody_saturn);
i_sat = kep_saturn(3);
OMG_sat = kep_saturn(4);
omg_sat = kep_saturn(5);
theta_sat = kep_saturn(6);
RM_theta = [cos(theta_sat), sin(theta_sat), 0; -sin(theta_sat), cos(theta_sat),0; 0,0,1];
RM_OMG = [ cos(OMG_sat),sin(OMG_sat), 0; -sin(OMG_sat), cos(OMG_sat), 0; 0, 0, 1];
RM_i = [1, 0, 0; 0, cos(i_sat), sin(i_sat);  0, -sin(i_sat), cos(i_sat)];
RM_omg = [cos(omg_sat), sin(omg_sat), 0; -sin(omg_sat), cos(omg_sat), 0; 0, 0, 1];
T = RM_theta*RM_omg*RM_i*RM_OMG;

% Fondamentalmente ho che il versore uscente dal piano e perpendicolare ad esso sara quello dato dal
% prodotto scalare di vinfmeno x vinfplus. L'orienzione : sara quella tale
% per cui le due vinf giacciono sullo stesso piano. Ok, dato questo come
% continuo per plottare l'iperbole ?
v_inf_min_saturn = T*v_inf_min';
v_inf_plus_saturn = T*v_inf_plus';
k_direction = cross(v_inf_min_saturn,v_inf_plus_saturn);
k_direction = k_direction/norm(k_direction);

% Get Lambert arc in Saturnocentric frame
[A]=T*[rx_arc_1, ry_arc_1, rz_arc_1]';
rx_arc_1_saturn = A(1,:);
ry_arc_1_saturn = A(2,:);
rz_arc_1_saturn = A(3,:);

[B]=T*[rx_arc_2, ry_arc_2, rz_arc_2]';
rx_arc_2_saturn = B(1,:);
ry_arc_2_saturn = B(2,:);
rz_arc_2_saturn = B(3,:);

%% PLOTTING 

figure(1)
grid on
hold on
whitebg(figure(1), 'black')
plot3(rx_mars,ry_mars,rz_mars);
plot3(rx_neptune,ry_neptune,rz_neptune);
plot3(rx_saturn,ry_saturn,rz_saturn);
legend('Mars Orbit', 'Neptune Orbit', 'Saturn Orbit')
title('Orbits in Heliocentric Frame')

%  Pork chop plot DV,TOF.
figure(2)
hold on
grid on
title('Pork chop plot contour and TOF for Mars to Saturn')
xlabel('Time of arrival');
ylabel('Time of departure');
axis equal
contour(t_arr,t_dep,Dv_matrix_1,50);
contour(t_arr,t_dep,TOF_matrix,20,'r','ShowText','on');
caxis([DV_MIN DV_MAX]);
colormap jet
datetick('x','yy/mm/dd','keepticks','keeplimits')
datetick('y','yy/mm/dd','keepticks','keeplimits')
set(gca,'XTickLabelRotation',45)
set(gca,'YTickLabelRotation',45)

%  Pork chop plot DV,TOF.
figure(3)
hold on
grid on
title('Pork chop plot contour and TOF for Saturn to Neptune')
xlabel('Time of arrival');
ylabel('Time of departure');
axis equal
contour(t_arr,t_dep,Dv_matrix_2,50);
contour(t_arr,t_dep,TOF_matrix,20,'r','ShowText','on');
caxis([DV_MIN DV_MAX]);
colormap jet
datetick('x','yy/mm/dd','keepticks','keeplimits')
datetick('y','yy/mm/dd','keepticks','keeplimits')
set(gca,'XTickLabelRotation',45)
set(gca,'YTickLabelRotation',45)


figure(4)
grid on
hold on
whitebg(figure(4), 'black')
plot3(rx_mars,ry_mars,rz_mars);
plot3(rx_neptune,ry_neptune,rz_neptune);
plot3(rx_saturn,ry_saturn,rz_saturn);
plot3(rx_arc_1, ry_arc_1, rz_arc_1,'y')
plot3(rx_arc_2, ry_arc_2, rz_arc_2,'w')
legend('Mars Orbit', 'Neptune Orbit', 'Saturn Orbit', 'First Transfer Arc','Second Transfer Arc')
title('Orbits and Lamberts Arc in Heliocentric Frame')

figure(5)
grid on 
hold on
title('Lambert Arcs in Planetocentric Frame')
plot3(rx_arc_1_saturn,ry_arc_1_saturn,rz_arc_1_saturn)
plot3(rx_arc_2_saturn,ry_arc_2_saturn,rz_arc_2_saturn)
xlabel('Km')
ylabel('Km')
legend('Before GA', 'After GA')
axis equal

figure(6)
hold on
plot(x_hyp_min,y_hyp_min)
zoomPlot (6,'x',[-10000000 3000000],'y',[-5000000 5000000]);
plot(x_hyp_plus,y_hyp_plus)
zoomPlot (6,'x',[-10000000 3000000],'y',[-5000000 5000000]);
plot(0,0,'*')
grid on
axis equal
xlabel('Km')
ylabel('Km')
title('Flyby Hyperbola')
legend('Entering Hyperbola', 'Exiting Hyperbola')

