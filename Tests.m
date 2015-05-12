% a=CmaesBox;
% a.beats_parameters=struct('DURATION',86400,'SIM_DT',4,'OUTPUT_DT',300);
% a.scenario_ptr='C:\Users\Felix\code\autoCalibrationProject\config\210E_truncated_frmode.xml';
% a.load_beats;
% a.beats_loaded=1;
% a.pems.bs=BeatsSimulation;
% a.pems.bs.load_scenario('C:\Users\Felix\code\autoCalibrationProject\config\210E_truncated_copy_to_simulate_pems_frmode.xml')
% a.pems.bs.run_beats(a.beats_parameters);
% a.set_masks_and_pems_data;
% TVmiles=TVMpH;
% a.TVMpH_reference_values.beats=TVmiles.calculate_from_beats(a);
% a.TVMpH_reference_values.pems = TVmiles.calculate_from_pems(a);
% a.pems_loaded=1;
% % a.run_assistant;


a=BeatsSimulation;
a.import_beats_classes('C:\Users\Felix\code\L0-utilities\simulation');
a.create_beats_object('C:\Users\Felix\code\autoCalibrationProject\config\210E_joined_frmode.xml',4,0,86400,300,'C:\Users\Felix\code\autoCalibrationProject\frmode');
a.run_beats_persistent;
a.plot_freeway_contour;

a.beats.set.demand_knob_for_link_id(128794214, 40);
a.run_beats_persistent;
a.plot_freeway_contour;

a.beats.set.demand_knob_for_link_id(135273082, 5);
a.run_beats_persistent;
a.plot_freeway_contour;