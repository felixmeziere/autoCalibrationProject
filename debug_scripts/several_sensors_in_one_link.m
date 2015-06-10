% a=BeatsSimulation;
% b.beats_simulation.load_scenario('C:\Users\Felix\code\autoCalibrationProject\config\210E_joined.xml');
% b=CmaesBox;
% b.load_xls('C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_210E_program.xlsx','C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_210E_Results.xlsx');
sensor_link = b.beats_simulation.scenario_ptr.get_sensor_link_map;
unique_link_ids=(unique(sensor_link(:,2)));
repeated_sensor_link=[];
for i=1:size(unique_link_ids,1)
    if (sum(ismember(sensor_link(:,2),unique_link_ids(i,1)))>1)
        repeated_sensor_link([end+1,end+sum(ismember(sensor_link(:,2),unique_link_ids(i,1)))],:)=sensor_link(ismember(sensor_link(:,2),unique_link_ids(i,1)),:);
    end    
end    

%Display IDs
disp('Ids of links that have several sensors and corresponding sensor ids :');
disp(repeated_sensor_link);
good_sensor_link=sensor_link(b.good_sensor_mask_pems,:);

%Plot their Pems data flow profile and template
clear leg;
close all;
unique_multiple_link_ids=unique(repeated_sensor_link(:,2));
for i=1:size(unique_multiple_link_ids,1)
    link_id=unique_multiple_link_ids(i,1);
    indices=find(b.pems.link_ids==link_id);
    h=figure;
    for j=1:size(indices,1)
        plot(b.pems.data.flw_in_veh(:,indices(j)))
        leg{j}=['Link ID= ',num2str(link_id),' | SensorID= ',num2str(sensor_link(indices(j),1)),' PeMS profile.'];
        hold on
    end
    c=b.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(link_id);
    c=c.demand*300;
    plot(c);
    leg{end+1}=['Link ID= ',num2str(link_id),' XML File demand profile'];
    h.Name=['Profiles for link id ',num2str(link_id)];
    title(['Profiles for link id ',num2str(link_id)]);
    legend(leg);
end    

% figures=findobj(0,'type','figure');
% fig_name= [pwd,'\','multiple_sensors_figures.fig'];
% savefig(figures,fig_name);f

%Plot their xml data flow profile

