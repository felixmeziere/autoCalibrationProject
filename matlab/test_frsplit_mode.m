clear
close all

root = fileparts(fileparts(mfilename('fullpath')));
cfg_folder = fullfile(root,'config');
cfg = fullfile(cfg_folder,'210E_truncated.xml');
cfg_frmode = fullfile(cfg_folder,'210E_truncated_frmode.xml');

% param=struct('DURATION',86000,'OUTPUT_DT',300,'SIM_DT',4);
% beats_fr_splits = BeatsSimulation;
% beats_fr_splits.load_scenario(cfg);
% beats_fr_splits.run_beats(param);
% beats_fr_splits.plot_freeway_contour

fr_param=struct('DURATION', 86000, 'OUTPUT_DT', 300, 'SIM_DT', 4, 'RUN_MODE', 'fw_fr_split_output');
beats_fr_dem = BeatsSimulation;
beats_fr_dem.load_scenario(cfg_frmode);
beats_fr_dem.run_beats(fr_param);
beats_fr_dem.plot_freeway_contour;

