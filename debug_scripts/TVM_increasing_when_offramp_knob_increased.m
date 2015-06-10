% a=BeatsSimulation;
% a.load_scenario('C:\Users\Felix\code\autoCalibrationProject\config\210E_joined.xml');
% a.import_beats_classes;
% beats_parameters.RUN_MODE='fw_fr_split_output';
% beats_parameters.SIM_DT=4;
% beats_parameters.DURATION=86400;
% beats_parameters.OUTPUT_DT=300;
% a.create_beats_object(beats_parameters);

%knobs set to one
disp('Knobs set to one : ');
a.beats.reset();
a.beats.set.demand_knob_for_link_id(-24031553,1);
a.beats.set.demand_knob_for_link_id(-792397270,1);
a.beats.set.demand_knob_for_link_id(-792397270,1);
a.run_beats_persistent;

TVMiles=TVM(b);

dt_hr=a.out_dt/3600;
% tvm1=sum(a.compute_performance.tot_flux)*dt_hr;
tvm1=TVMiles.calculate_from_beats;
disp(['TVM = ', num2str(tvm1)]);



a.beats.reset();
disp('Now increasing and decreasing two off-ramps');
disp(a.scenario_ptr.get_link_byID(-24031553).link_type.ATTRIBUTE.name);
disp(a.scenario_ptr.get_link_byID(-792397270).link_type.ATTRIBUTE.name);
disp('Knobs set to three :');
a.beats.set.demand_knob_for_link_id(-24031553,3);
a.beats.set.demand_knob_for_link_id(-792397270,3);
a.run_beats_persistent;
% tvm2=sum(a.compute_performance.tot_flux)*dt_hr;
tvm2=TVMiles.calculate_from_beats;
disp(['TVM = ', num2str(tvm2)]);
disp('Knobs set to 0.5 :');
a.beats.reset();
a.beats.set.demand_knob_for_link_id(-24031553,0.5);
a.beats.set.demand_knob_for_link_id(-792397270,0.5);
a.run_beats_persistent;
% tvm3=sum(a.compute_performance.tot_flux)*dt_hr;
tvm3=TVMiles.calculate_from_beats;
disp(['TVM = ', num2str(tvm3)]);

