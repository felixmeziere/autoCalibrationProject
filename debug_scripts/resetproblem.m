clear
close all


beats_parameters=struct('DURATION',86400,'SIM_DT',4,'OUTPUT_DT',300,'RUN_MODE','fw_fr_split_output','OUTPREFIX','C:\Users\Felix\code\autoCalibrationProject\out');
a=BeatsSimulation;
a.import_beats_classes;
a.create_beats_object('C:\Users\Felix\code\autoCalibrationProject\config\210E_joined_frmode_beats.xml',beats_parameters);


a.beats.reset()
a.run_beats_persistent;
a.plot_freeway_contour;

a.beats.reset()
a.run_beats_persistent;
a.plot_freeway_contour;