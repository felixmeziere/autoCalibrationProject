a=CmaesBox;
a.beats_parameters=struct('DURATION',86400,'SIM_DT',4,'OUTPUT_DT',300);
a.scenario_ptr='C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\test.xml';
a.load_beats;
a.beats_loaded=1;
a.pems.bs=BeatsSimulation;
a.pems.bs.load_scenario('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\testcopy.xml')
a.pems.bs.run_beats(a.beats_parameters);
a.set_masks_and_pems_data;
TVmiles=TVMpH;
a.TVMpH_reference_values.beats=TVmiles.calculate_from_beats(a);
a.TVMpH_reference_values.pems = TVmiles.calculate_from_pems(a);
a.pems_loaded=1;
a.run_assistant;