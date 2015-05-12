clear
close all

root = fileparts(fileparts(mfilename('fullpath')));
cfg_folder = fullfile(root,'config');
report_folder = fullfile(root,'_reports');
out_folder = fullfile(root,'_out');

cfg = fullfile(cfg_folder,'210E_joined.xml');
cfg_nosplits = fullfile(cfg_folder,'210E_joined_nosplits.xml');
cfg_remove_offramps = fullfile(cfg_folder,'210E_joined_removeofframp.xml');

ptr_norm = BeatsSimulation;
ptr_norm.load_scenario(cfg);
ptr_nosplits_norm = BeatsSimulation;
ptr_nosplits_norm.load_scenario(cfg_nosplits);

ptr_fr = BeatsSimulation;
ptr_fr.load_scenario(cfg);
ptr_nosplits_fr = BeatsSimulation;
ptr_nosplits_fr.load_scenario(cfg_nosplits);

% run splits in normal mode                                     GOOD RESULT
ptr_norm.run_beats(struct('SIM_DT',4))
ptr_norm.plot_freeway_contour;

% run with splits in fw_fr_split_output mode                    GOOD RESULT        
ptr_fr.run_beats(struct('SIM_DT',4,'RUN_MODE','fw_fr_split_output'))
ptr_fr.plot_freeway_contour;

% run no splits normal mode                                      BAD RESULT
ptr_nosplits_norm.run_beats(struct('SIM_DT',4))
ptr_nosplits_norm.plot_freeway_contour;

% run no splits frdemand mode                                    BAD RESULT
ptr_nosplits_fr.run_beats(struct('SIM_DT',4,'RUN_MODE','fw_fr_split_output'))
ptr_nosplits_fr.plot_freeway_contour;

% reports
ptr_norm.scenario_ptr.report(cfg)

writetable(ptr_norm.scenario_ptr.get_link_table,fullfile(out_folder,'link_table.xls'));

ptr_beats = BeatsSimulation;
ptr_beats.load_scenario(cfg);
ptr_beats.load_simulation_output(fullfile(out_folder,'withsplit_frmode'))
a=sum(ptr_beats.compute_performance.tot_flux)

ptr_beats2 = BeatsSimulation;
ptr_beats2.load_scenario(cfg_remove_offramps);
ptr_beats2.load_simulation_output(fullfile(out_folder,'withsplit_frmode_offrampremoved'))
b=sum(ptr_beats2.compute_performance.tot_flux)
