% a=BeatsSimulation;
% a.load_scenario('C:\Users\Felix\code\autoCalibrationProject\config\210E_joined.xml');
% a.import_beats_classes;
% beats_parameters.RUN_MODE='fw_fr_split_output';
% beats_parameters.SIM_DT=4;
% beats_parameters.DURATION=86400;
% beats_parameters.OUTPUT_DT=300;
% a.create_beats_object(beats_parameters);
% 
% %nothing changed
% a.beats.reset();
% a.beats.set.demand_knob_for_link_id(-24031553,1);
% a.beats.set.demand_knob_for_link_id(-792397270,1);
% a.beats.set.demand_knob_for_link_id(-792397270,1);
% a.run_beats_persistent;
% a.plot_freeway_contour;
% 
% %offramps
% a.beats.reset();
% % a.beats.set.demand_knob_for_link_id(-24031553,100);
% a.beats.set.demand_knob_for_link_id(-792397270,15);
% a.run_beats_persistent;
% a.plot_freeway_contour;
% 
% %onramp
% a.beats.reset();
% a.beats.set.demand_knob_for_link_id(-24031553,1);
% a.beats.set.demand_knob_for_link_id(-792397270,1);
% a.beats.set.demand_knob_for_link_id(-873337960,100);
% a.run_beats_persistent;
% a.plot_freeway_contour;





% b=BeatsSimulation;
% b.load_scenario('C:\Users\Felix\code\autoCalibrationProject\config\210E_joined.xml');
% b.load_simulation_output('C:\Users\Felix\code\beats\data\test\output\test')
% b.plot_freeway_contour
% b.beats.set.demand_knob_for_link_id(-24031553);

% for i=1:7
%     id=a.knobs.link_ids(i);
%     sum(a.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(a.knobs.link_ids(i)).demand)*300
% end    
% 
% sum(a.pems.data.flw_in_veh(:,find(a.pems.link_ids==128809372),1))




