% load();
% a=obj;
% clear obj
% first.beats_simulation.import_beats_classes;
% first.beats_simulation.create_beats_object(first.beats_parameters);
% first.evaluate_error_function(first.knobs.current_value);

% %Pems linear freeway indices
pems_normalinlinear_indices=[];

pemsids=first.pems.link_ids;
for i=1:size(first.pems.linear_link_ids,2)
    index=find(pemsids==first.pems.linear_link_ids(i));
	pems_normalinlinear_indices(1,i)=index(1);
    pemsids(index(1))=0;
end

% %Beats linear freeway indices
beats_normalinlinear_indices=[];

for i=1:size(first.link_ids_beats,2)
	beats_normalinlinear_indices(1,i)=find(first.link_ids_beats==first.linear_link_ids(i));
end




% %set monitored beats profiles
% 
beats_normalinlinear_monitored_mainline_indices=beats_normalinlinear_indices(first.send_mask_beats_to_linear_space(first.good_mainline_mask_beats));
beats_normalinlinear_monitored_source_indices=beats_normalinlinear_indices(first.send_mask_beats_to_linear_space(first.good_source_mask_beats));
beats_normalinlinear_monitored_sink_indices=beats_normalinlinear_indices(first.send_mask_beats_to_linear_space(first.good_sink_mask_beats));
% 
beats_linear_monitored_mainline_ids=first.link_ids_beats(beats_normalinlinear_monitored_mainline_indices);
beats_linear_monitored_source_ids=first.link_ids_beats(beats_normalinlinear_monitored_source_indices);
beats_linear_monitored_sink_ids=first.link_ids_beats(beats_normalinlinear_monitored_sink_indices);








%set monitored pems profiles

pems_normalinlinear_monitored_mainline_indices=pems_normalinlinear_indices(first.send_mask_pems_to_linear_space(first.good_mainline_mask_pems));
pems_normalinlinear_monitored_source_indices=pems_normalinlinear_indices(first.send_mask_pems_to_linear_space(first.good_source_mask_pems));
pems_normalinlinear_monitored_sink_indices=pems_normalinlinear_indices(first.send_mask_pems_to_linear_space(first.good_sink_mask_pems));

pems_linear_monitored_mainline_ids=first.pems.link_ids(pems_normalinlinear_monitored_mainline_indices);
pems_linear_monitored_source_ids=first.pems.link_ids(pems_normalinlinear_monitored_source_indices);
pems_linear_monitored_sink_ids=first.pems.link_ids(pems_normalinlinear_monitored_sink_indices);


%plots
LOnes=[];

for i =1:sum(first.good_mainline_mask_pems)
	figure;
	plot(first.pems.data.flw_in_veh(:,pems_normalinlinear_monitored_mainline_indices(i),first.current_day));
    hold on
    plot(first.beats_simulation.outflow_veh{1,1}(:,beats_normalinlinear_monitored_mainline_indices(i)));
	title(['Beats vs. PeMS Monitored mainline link number ',num2str(i),' |  id = ',num2str(beats_linear_monitored_mainline_ids(i))]);
    legend('PeMS profile','Beats output profile');
    hold off
    LOnes(i)=norm(first.pems.data.flw_in_veh(:,pems_normalinlinear_monitored_mainline_indices(i),first.current_day)-first.beats_simulation.outflow_veh{1,1}(:,beats_normalinlinear_monitored_mainline_indices(i)),1);
end	

figure
plot(LOnes);

for i=1:sum(first.good_source_mask_pems)
    figure;
	plot(first.pems.data.flw_in_veh(:,pems_normalinlinear_monitored_source_indices(i),first.current_day));
    hold on;
    plot(first.beats_simulation.outflow_veh{1,1}(:,beats_normalinlinear_monitored_source_indices(i)));
	title(['PeMS Monitored source link number ',num2str(i),' |  id = ',num2str(pems_linear_monitored_source_ids(i))]);
    legend('PeMS profile','Beats output profile');
    hold off;
end	

for i=1:sum(first.good_sink_mask_pems)
figure;
	plot(first.pems.data.flw_in_veh(:,pems_normalinlinear_monitored_sink_indices(i),first.current_day));
    hold on;
    plot(first.beats_simulation.outflow_veh{1,1}(:,beats_normalinlinear_monitored_sink_indices(i)));
	title(['Beats vs. PeMS Monitored sink link number ',num2str(i),'|  id = ',num2str(pems_linear_monitored_sink_ids(i))]);
    legend('PeMS profile','Beats output profile');
    hold off;
end	

% 
% for i =1:sum(first.good_mainline_mask_beats)
% 	figure;
% 	plot(first.beats_simulation.outflow_veh{1,1}(:,beats_normalinlinear_monitored_mainline_indices(i)));
% 	title(['Beats Monitored mainline link number ',num2str(i),' |  id = ',num2str(beats_linear_monitored_mainline_ids(i))]);
% end	
% 
% for i=1:sum(first.good_source_mask_beats)
% figure;
% 	plot(first.beats_simulation.outflow_veh{1,1}(:,beats_normalinlinear_monitored_source_indices(i)));
% 	title(['Beats Monitored source link number ',num2str(i),' |  id = ',num2str(beats_linear_monitored_source_ids(i))]);
% end	
% % 
% for i=1:sum(first.good_sink_mask_beats)
% figure;
% 	plot(first.beats_simulation.outflow_veh{1,1}(:,beats_normalinlinear_monitored_sink_indices(i)));
% 	title(['Beats Monitored source link number ',num2str(i),' |  id = ',num2str(beats_linear_monitored_sink_ids(i))]);
% end	


% %Plot unmonitored beats profiles
% 
% pems_normalinlinear_unmonitored_source_indices=pems_normalinlinear_indices(first.send_mask_pems_to_linear_space(logical(first.source_mask_pems.*first.good_source_mask_pems)));
% pems_normalinlinear_unmonitored_sink_indices=pems_normalinlinear_indices(first.send_mask_pems_to_linear_space(first.good_sink_mask_pems));
% 
% pems_linear_unmonitored_mainline_ids=first.pems.linear_link_ids(first.send_mask_pems_to_linear_space(first.good_mainline_mask_pems));
% pems_linear_unmonitored_source_ids=first.pems.linear_link_ids(first.send_mask_pems_to_linear_space(first.good_source_mask_pems));
% pems_linear_unmonitored_sink_ids=first.pems.linear_link_ids(first.send_mask_pems_to_linear_space(first.good_sink_mask_pems));
% 
% 
% %Plot unmonitored PeMS profiles
% 
% beats_normalinlinear_unmonitored_mainline_indices=beats_normalinlinear_indices(first.send_mask_beats_to_linear_space(first.good_mainline_mask_beats));
% beats_normalinlinear_unmonitored_source_indices=beats_normalinlinear_indices(first.send_mask_beats_to_linear_space(first.good_source_mask_beats));
% beats_normalinlinear_unmonitored_sink_indices=beats_normalinlinear_indices(first.send_mask_beats_to_linear_space(first.good_sink_mask_beats));
% % 
% beats_linear_unmonitored_mainline_ids=first.linear_link_ids(first.send_mask_beats_to_linear_space(first.good_mainline_mask_beats));
% beats_linear_unmonitored_source_ids=first.linear_link_ids(first.send_mask_beats_to_linear_space(first.good_source_mask_beats));
% beats_linear_unmonitored_sink_ids=first.linear_link_ids(first.send_mask_beats_to_linear_space(first.good_sink_mask_beats));

% index=find(first.link_ids_beats==128792525);
% figure;
% plot(first.beats_simulation.outflow_veh{1,1}(:,index));
% hold on
% demandp=first.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(128792525);
% plot(demandp.demand*300);
% title('On-Ramp after 21 : link id=128792525, VDS=716606');
% legend('Beats output','XML profile');
% hold off
% 
% index=find(first.link_ids_beats==721105516);
% figure;
% plot(first.beats_simulation.outflow_veh{1,1}(:,index));
% hold on
% demandp=first.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(721105516);
% plot(demandp.demand*300);
% title('On-Ramp after 22 : link id=721105516, VDS=718212');
% legend('Beats output','XML profile');
% hold off
% 
% index=find(first.link_ids_beats==-781754904);
% figure;
% plot(first.beats_simulation.outflow_veh{1,1}(:,index));
% hold on
% demandp=first.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(-781754904);
% plot(demandp.demand*300);
% title('Off-Ramp before 23 : link id=781754904, VDS=769705');
% legend('Beats output','XML profile');
% hold off
