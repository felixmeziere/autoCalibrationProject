clear
close all

root = fileparts(fileparts(mfilename('fullpath')));
cfg_folder = fullfile(root,'config');
cfg = fullfile(cfg_folder,'210E_joined.xml');
cfg_frmode = fullfile(cfg_folder,'210E_joined_frmode_beats.xml');

normal = BeatsSimulation;
normal.load_scenario(cfg);
normal.run_beats(struct('SIM_DT',4));

frdem = BeatsSimulation;
frdem.load_scenario(cfg_frmode);
frdem.run_beats(struct('SIM_DT',4,'RUN_MODE','fw_fr_split_output'));


frdemi = BeatsSimulation;
frdemi.load_scenario(cfg_frmode);
frdemi.load_simulation_output(fullfile(root,'_output','frmode'));
frdemi.plot_freeway_contour


save zzz

normal.plot_freeway_contour
frdem.plot_freeway_contour

%% compare source flows with demnds. This check out.
% normal.plot_source_queues_and_demands
% frdem.plot_source_queues_and_demands


%% compare offramp flows to templates
ds  = xml_read(fullfile(root,'config','fr_demands_beats.xml'));

time = 0:300:86100;
for i=1:length(ds.demandProfile)
    dp = ds.demandProfile(i);
    link_id = dp.ATTRIBUTE.link_id_org;
    dem = dp.demand.CONTENT;
    
    sim = frdem.get_output_for_link_id(link_id);

    figure
    plot(time,dem,'b','LineWidth',2)
    hold on
    plot(time,sim.flw_in_vph/3600,'r')
    grid
    title(sprintf('link id = %d',link_id))
    
end

% all ok except: 756090723, -24558231, -781754904

% fwy = frdem.scenario_ptr.get_freeway_structure;
% linear_fwy_type = frdem.scenario_ptr.get_link_types(fwy.linear_fwy_ind);
% linear_fwy_ids = frdem.scenario_ptr.get_link_ids(fwy.linear_fwy_ind);
% 
% x = find(linear_fwy_ids==-781754904)
% linear_fwy_type(x)



