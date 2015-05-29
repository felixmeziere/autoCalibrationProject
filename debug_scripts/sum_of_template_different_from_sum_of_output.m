clear all
close all
scenario_ptr='C:\Users\Felix\code\autoCalibrationProject\config\210E_joined_frmode_beats.xml';
beats_parameters=struct('OUTPUT_DT','300','SIM_DT','4','RUN_MODE','fw_fr_split_output','DURATION','86400');
f=BeatsSimulation;
f.import_beats_classes;
f.load_scenario(scenario_ptr);
f.create_beats_object(beats_parameters);
f.run_beats_persistent;


%this is an offramp
link=f.scenario_ptr.get_link_byID(-792345191);
disp(link.link_type.ATTRIBUTE.name);
%this is the sum of its template (whole day, in vehicles).
disp('sum of template');
dp=f.scenario_ptr.get_demandprofiles_with_linkIDs(-792345191);
sum_of_template_in_veh=sum(dp.demand)*dp.dt;
disp(sum_of_template_in_veh);
%this is the sum of its output (whole day, in vehicles).
disp('sum of output');
disp(sum(f.get_output_for_link_id(-792345191).flw_in_veh));
disp('They are the same, as we expect');

%they are the same, as we expect.




%this is some other offramp
disp('This is some other offramp');
link=f.scenario_ptr.get_link_byID(-128793036);
disp(link.link_type.ATTRIBUTE.name);
%this is the sum of its template (whole day, in vehicles).
disp('sum of template');
dp=f.scenario_ptr.get_demandprofiles_with_linkIDs(-128793036);
sum_of_template_in_veh=sum(dp.demand)*dp.dt;
disp(sum_of_template_in_veh);
%this is the sum of its output (whole day, in vehicles).  
disp('sum of output');
disp(sum(f.get_output_for_link_id(-128793036).flw_in_veh));
disp('Why, in this case, the values are so different (1/3) ? I have observed that this phenomenon only happens to some offramps. I understand that an off ramp cannot get vehicles if there are no vehicles on the freeway, but here, the opposite is happening : the offramp is getting 3 times more vehicles than it should.');

%why, in this case, the values are so different (1/3) ? I have observed
%that this phenomenon only happens to some offramps. I understand that an off
%ramp cannot get vehicles if there are no vehicles on the freeway, but
%here, the opposite is happening : the offramp is getting 3 times more
%vehicles than it should.


%Below shows the sum of output divided by the sum of template for all on
%ramps and off ramps.

%THE LAST AUTOCALIBRATIONPROJECT CODE IS NEEDED AND THE PATHS HAVE TO BE
%CHANGED IN CMAES_210E_PROGRAM.XLS AND 210E_JOINED_FRMODE_BEATS.XML 

%It should be 1 for all. We see that the problem happens to some offramps and no onramps.
%These two lists are plotted in the same graph.

%create onramps and offramps with AlgorithmBox data

a=CmaesBox;
a.load_xls('C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_210E_program.xlsx','C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_210E_Results.xlsx');
onramps=a.link_ids_beats(logical(a.source_mask_beats.*~a.mainline_mask_beats));
offramps=a.link_ids_beats(logical(a.sink_mask_beats.*~a.mainline_mask_beats));



%assumes onramps and offramps containing the onramps and offramps link ids has been created

for i=1:size(offramps,2)
dp=f.scenario_ptr.get_demandprofiles_with_linkIDs(offramps(i));
sum_of_template=sum(dp.demand)*dp.dt;
sum_of_output=sum(f.get_output_for_link_id(offramps(i)).flw_in_veh);
c(i)=sum_of_output/sum_of_template;
end

for i=1:size(onramps,2)
dp=f.scenario_ptr.get_demandprofiles_with_linkIDs(onramps(i));
sum_of_template=sum(dp.demand)*dp.dt;
sum_of_output=sum(f.get_output_for_link_id(onramps(i)).flw_in_veh);
d(i)=sum_of_output/sum_of_template;
end

c=reshape(c,[],1);
d=reshape(d,[],1);

plot(c);
hold on;
plot(d);
%red is onramps and blue is offramps.

disp ('Below shows the sum of output divided by the sum of template for all on ramps and off ramps. It should be 1 for all. We see that the problem happens to some offramps and no onramps.');
disp('offramps');
disp(c);

disp('onramps');
disp(d);



