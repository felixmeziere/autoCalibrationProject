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
link=f.scenario_ptr.get_link_byID(-24017890);
disp(link.link_type.ATTRIBUTE.name);
%this is the sum of its template (whole day, in vehicles).
disp('sum of template');
dp=f.scenario_ptr.get_demandprofiles_with_linkIDs(-24017890);
sum_of_template_in_veh=sum(dp.demand)*dp.dt;
disp(sum_of_template_in_veh);
%this is the sum of its output (whole day, in vehicles).  
disp('sum of output');
disp(sum(f.get_output_for_link_id(-24017890).flw_in_veh));
disp('Why, in this case, the values are so different (1/6) ? I have observed that this phenomenon only happens to some offramps. I understand that an off ramp cannot get vehicles if there are no vehicles on the freeway, but here, the opposite is happening : the offramp is getting 3 times more vehicles than it should.');

%why, in this case, the values are so different (1/3) ? I have observed
%that this phenomenon only happens to some offramps. I understand that an off
%ramp cannot get vehicles if there are no vehicles on the freeway, but
%here, the opposite is happening : the offramp is getting 3 times more
%vehicles than it should.

%A first answer is that the knobs do not seem to work correctly.


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

f.beats.reset();
for i=1:size(offramps,2)
    f.beats.set.demand_knob_for_link_id(offramps(i),3);
end

for i=1:size(onramps,2)
    f.beats.set.knob_for_offramp_link_id(onramps(i),3);
end

for i=1:size(offramps,2)
dp=f.scenario_ptr.get_demandprofiles_with_linkIDs(offramps(i));
sum_of_template=sum(dp.demand)*dp.dt;
sum_of_output=sum(f.get_output_for_link_id(offramps(i)).flw_in_veh);
off_knobs_set_to_3(i)=sum_of_output/sum_of_template;
end

for i=1:size(onramps,2)
dp=f.scenario_ptr.get_demandprofiles_with_linkIDs(onramps(i));
sum_of_template=sum(dp.demand)*dp.dt;
sum_of_output=sum(f.get_output_for_link_id(onramps(i)).flw_in_veh);
on_knobs_set_to_3(i)=sum_of_output/sum_of_template;
end

c=reshape(c,[],1);
d=reshape(d,[],1);
on_knobs_set_to_3=reshape(on_knobs_set_to_3,[],1);
off_knobs_set_to_3=reshape(off_knobs_set_to_3,[],1);

%all knobs set to one
plot(c);
hold on;
plot(d);
%red is onramps and blue is offramps.

%all knobs set to three
plot(off_knobs_set_to_3);
hold on;
plot(on_knobs_set_to_3);


disp ('Below shows the sum of output divided by the sum of template for all on ramps and off ramps, when knobs are set to one ore three. It should be 1 and 3 for all. The knobs do not seem to act on the output of the links, so I dont think I understand how they work. Also, some offramp values when knobs=1 are not 1, which is surprising');
disp('offramps knobs=1');
disp(c);
disp('offramps knobs=3');
disp(off_knobs_set_to_3);



disp('onramps knobs=1');
disp(d);
disp('onramps knobs=3');
disp(on_knobs_set_to_3);



