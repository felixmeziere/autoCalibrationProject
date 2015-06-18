% original=ScenarioPtr;
% original.load('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\210E_joined_original.xml');
% new=ScenarioPtr;
% new.load('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\210E_joined_original.xml');
X=load_210e_setup;

dirname='C:\Users\Felix\code\autoCalibrationProject\pems_data\210E\_processed\';

sensors=b.scenario.SensorSet.sensor;
profiles=b.scenario.DemandSet.demandProfile;
vds2id=b.get_sensor_vds2id_map;
id2link=b.get_sensor_link_map;
vds2id=[vds2id(:,1),id2link(:,2)];


%find multiple sensors in same link.......................................
multiple_sensor_index2vds2id2link=[];
unique_link_ids=unique(id2link(:,2),'stable');
vds=vds2id(:,1);
for i=1:size(unique_link_ids,1)
    indexes=find(id2link(:,2)==unique_link_ids(i,1));
    if (size(indexes,1)>1)
        multiple_sensor_index2vds2id2link([end+1,end+sum(ismember(id2link(:,2),unique_link_ids(i,1)))],:)=[indexes,vds(indexes,1),id2link(indexes,:)];
    end    
end

%define which to keep (more than one on same link will be summed)..........
multiple_sensor_vds_to_use=[717595,765477,717679,717683,774035];

%For tuesdays into new...................................................
for i=1:size(profiles,2)
    vds=vds2id(ismember(vds2id(:,2),profiles(i).ATTRIBUTE.link_id_org),1);
    for k=1:size(vds,1)
        if ismember(vds(k,1),X.bad_vds)
            vds(k,1)=X.use_as_template(ismember(X.bad_vds,vds(k,1)));
        end
    end 
    if size(vds,1)>1
        temp=[];
        for k=1:size(vds,1)
            if ismember(vds(k,1),multiple_sensor_vds_to_use)
                temp(end+1,1)=vds(k,1);
            end        
        end  
        vds=temp;
    end
    template=zeros(288,1);
    for k=1:size(vds,1)
        load([dirname,'tmpl_',num2str(vds(k,1)),'.mat']);
        template=template+tmpl(:,2)/(12*300);
    end    
    new.scenario.DemandSet.demandProfile(i).demand.CONTENT(1,:)=transpose(template(:,1));
end    
% 
new.save('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\210E_tuesdays.xml');


%%Change Lanes
% links=original.scenario.NetworkSet.network.LinkList.link;
% for i=1:size(links,2)
%     new.scenario.NetworkSet.network.LinkList.link(i).ATTRIBUTE.lanes=links(i).ATTRIBUTE.lanes/1.2342;
% end    
% new.save('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\210E_tuesdays_modified_lanes.xml');

%Change capacities
% fds=original.scenario.FundamentalDiagramSet.fundamentalDiagramProfile;
% for i=1:size(fds,2)
%     new.scenario.FundamentalDiagramSet.fundamentalDiagramProfile(i).fundamentalDiagram.ATTRIBUTE.capacity=fds(i).fundamentalDiagram.ATTRIBUTE.capacity/1.2342;
% end    
% new.save('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\210E_tuesdays_modified_capacities.xml');
