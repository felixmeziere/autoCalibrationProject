%  
%  b=BeatsSimulation;
%  b.load_scenario('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\210E.xml');
%  original=ScenarioPtr;
%  original.load('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\210E.xml');
%  c=b.scenario_ptr.extract_linear_fwy_indices;
%  c=reshape(c,[],1);
%  d=b.scenario_ptr.get_link_ids;
%  d=reshape(d,[],1);
%  d=d(c);
%  e=b.scenario_ptr.get_link_types;
%  e=reshape(e,[],1);
%  e=e(c);
%  f=cell(189,2);
%  for i=1:189
%     f{i,1}=d(i,1);
%     f{i,2}=cell2mat(e(i,1));
%  end    
%  disp(f);
%  final=ScenarioPtr;
%  final.load('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\210E_light_no_offramps.xml');
%  link_ids=original.get_link_ids;
%  link_ids_final=cell2mat(f(1:25,1));
%  save simplescensettings;
%  clear all;
%  load simplescensettings;
%  
% % link_ids_final=link_ids_final(~ismember(link_ids_final, link_ids(original.is_sink_link)));
% 
% k=1;
% l=1;
% m=1;
% n=1;
% o=1;
% for i =1:size(link_ids_final,1)
%         link_id=link_ids_final(i,1);
%         link=original.get_link_byID(link_id);
%         final.scenario.NetworkSet.network.LinkList.link(i)=link;
%         nodeList=original.scenario.NetworkSet.network.NodeList.node;
%         demandList=original.scenario.DemandSet.demandProfile;
%         sensorList=original.scenario.SensorSet.sensor;
%         fdList=original.scenario.FundamentalDiagramSet.fundamentalDiagramProfile;
%         spList=original.scenario.SplitRatioSet.splitRatioProfile;
%         for j=1:size(nodeList,2)
%             if (nodeList(j).ATTRIBUTE.id==link.begin.ATTRIBUTE.node_id || nodeList(j).ATTRIBUTE.id==link.end.ATTRIBUTE.node_id)
%                 final.scenario.NetworkSet.network.NodeList.node(k).inputs=nodeList(j).inputs;
%                 final.scenario.NetworkSet.network.NodeList.node(k).outputs=nodeList(j).outputs;
%                 final.scenario.NetworkSet.network.NodeList.node(k).position=nodeList(j).position;
%                 final.scenario.NetworkSet.network.NodeList.node(k).node_type=nodeList(j).node_type;
%                 final.scenario.NetworkSet.network.NodeList.node(k).ATTRIBUTE=nodeList(j).ATTRIBUTE;
%                 k=k+1;
%             end
%         end
%         for j= 1:size(demandList,2)
%             if (demandList(1,j).ATTRIBUTE.link_id_org==link_id)
%                 final.scenario.DemandSet.demandProfile(l).demand=demandList(j).demand;
%                 final.scenario.DemandSet.demandProfile(l).ATTRIBUTE=demandList(j).ATTRIBUTE;
%                 l=l+1;
%             end 
%         end
%         for j= 1:size(sensorList,2)
%             if (sensorList(1,j).ATTRIBUTE.link_id==link_id)
%                 final.scenario.SensorSet.sensor(m).display_position=sensorList(j).display_position;
%                 final.scenario.SensorSet.sensor(m).parameters=sensorList(j).parameters;
%                 final.scenario.SensorSet.sensor(m).sensor_type=sensorList(j).sensor_type;
%                 final.scenario.SensorSet.sensor(m).ATTRIBUTE=sensorList(j).ATTRIBUTE;
%                 m=m+1;
%             end    
%         end
%         for j= 1:size(fdList,2)
%             if (fdList(1,j).ATTRIBUTE.link_id==link_id)
%                 final.scenario.FundamentalDiagramSet.fundamentalDiagramProfile(n).fundamentalDiagram=fdList(j).fundamentalDiagram;
%                 final.scenario.FundamentalDiagramSet.fundamentalDiagramProfile(n).fundamentalDiagramType=fdList(j).fundamentalDiagramType;
%                 final.scenario.FundamentalDiagramSet.fundamentalDiagramProfile(n).calibrationAlgorithmType=fdList(j).calibrationAlgorithmType;
%                 final.scenario.FundamentalDiagramSet.fundamentalDiagramProfile(n).ATTRIBUTE=fdList(j).ATTRIBUTE;
%                 n=n+1;
%             end    
%         end
%         for j= 1:size(spList,2)
%             for p=1:size(final.scenario.NetworkSet.network.NodeList.node,2)
%                 if (spList(1,j).ATTRIBUTE.node_id==final.scenario.NetworkSet.network.NodeList.node(p).ATTRIBUTE.id)
%                     final.scenario.SplitRatioSet.splitRatioProfile(o).splitratio=spList(j).splitratio;
%                     final.scenario.SplitRatioSet.splitRatioProfile(o).ATTRIBUTE=spList(j).ATTRIBUTE;
%                     o=o+1;
%                 end    
%             end
%         end
% end    
% 
% final.save('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\test.xml');
clear beats;
beats=BeatsSimulation;
beats.load_scenario('C:\Users\Felix\code\autoCalibrationProject\beats_scenarios\test.xml');
param=struct('DURATION',86000,'OUTPUT_DT',300,'SIM_DT',4);
beats.run_beats(param);
beats.plot_freeway_contour;