scenario_ptr='C:\Users\Felix\code\autoCalibrationProject\config\210E_joined_frmode_beats.xml';
beats_parameters=struct('OUTPUT_DT','300','SIM_DT','4','RUN_MODE','fw_fr_split_output','DURATION','86400');
a=BeatsSimulation;
a.import_beats_classes;
a.load_scenario(scenario_ptr);
a.create_beats_object(beats_parameters);
a.run_beats_persistent;


%this is an onramp
link=a.scenario_ptr.get_link_byID(128793059);
disp(link.link_type.ATTRIBUTE.name);
%this is the sum of its template (whole day, in vehicles).
disp('sum of template');
dp=a.scenario_ptr.get_demandprofiles_with_linkIDs(128793059);
sum_of_template_in_veh=sum(dp.demand)*dp.dt;
disp(sum_of_template_in_veh);
%this is the sum of its output (whole day, in vehicles).
disp('sum of output');
disp(sum(a.get_output_for_link_id(128793059).flw_in_veh));
disp('They are the same, as we expect');

%they are the same, as we expect.




%this is some other offramp
link=a.scenario_ptr.get_link_byID(-128793036);
disp(link.link_type.ATTRIBUTE.name);
%this is the sum of its template (whole day, in vehicles).
disp('sum of template');
dp=a.scenario_ptr.get_demandprofiles_with_linkIDs(-128793036);
sum_of_template_in_veh=sum(dp.demand)*dp.dt;
disp(sum_of_template_in_veh);
%this is the sum of its output (whole day, in vehicles).  
disp('sum of output');
disp(sum(a.get_output_for_link_id(-128793036).flw_in_veh));
disp('Why, in this case, the values are so different (1/3) ? I have observed that this phenomenon is not correlated with the fact of being an on-ramp or off-ramp.');

%why, in this case, the values are so different (1/3) ? I have observed
%that this phenomenon is not correlated with the fact of being an on-ramp
%or off-ramp.



