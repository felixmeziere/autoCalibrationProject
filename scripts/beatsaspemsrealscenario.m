% a=CmaesBox;
% a.load_xls('C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_210E_program.xlsx','C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_210E_Results.xlsx');
normalstruct=a.beats_parameters;
normalstruct.RUN_MODE='normal',
b=BeatsSimulation;
b.load_scenario('C:\Users\Felix\code\autoCalibrationProject\config\210E_joined.xml');
b.create_beats_object(normalstruct);
b.run_beats_persistent;
b.plot_freeway_contour;
