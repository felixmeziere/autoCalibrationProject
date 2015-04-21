% fclear
close all

%here = fileparts(mfilename('fullpath'));
% config = fullfile(here,'210E.xml');
% 
% ptr = BeatsSimulation;
% ptr.load_scenario(config);
% ptr.run_beats(struct('SIM_DT',4));
% ptr.plot_freeway_contour;
% 
% ptr.plot_performance

load aaa

% pems performance

% process and load data
pems = PeMS5minData;
here = fileparts(mfilename('fullpath'));
processed_folder =fullfile(here,'processed');

district = 7;
vds2id = ptr.scenario_ptr.get_sensor_vds2id_map;
for i=1:size(vds2id,1)
   vds(i).sensor_vds = vds2id(i,1); 
end
days = (datenum(2014,10,1):datenum(2014,10,10));
% pems.dch2mat(processed_folder,district,vds,days);
pems.load(processed_folder, vds2id(:,1), days)
X=pems.get_data_batch_aggregate(vds2id(:,1), days(1), 'smooth', true);

is_bad_detector = all(isnan(X.flw), 1);

flw = X.flw(:, ~is_bad_detector);

figure
plot(1:288,flw)
ylabel('Total vehicles [veh]')
title(sprintf('TVH = %.0f veh.hr',sum(flw)*300));



%  beats performance
link_ids = ptr.scenario_ptr.get_link_ids;
link_types = ptr.scenario_ptr.get_link_types;
sensor_link = ptr.scenario_ptr.get_sensor_link_map;

links_with_sensors = ismember(link_ids,sensor_link(:,2));

P=ptr.compute_performance();

figure
plot(P.time,P.tot_veh)
ylabel('Total vehicles [veh]')
title(sprintf('TVH = %.0f veh.hr',sum(P.tot_veh)*P.dt_hr));

% total vehicle miles
figure
plot(P.time,P.tot_flux)
ylabel('Total flux [veh.miles/hr]')
title(sprintf('TVM = %.0f veh.mile',sum(P.tot_flux)*P.dt_hr));

