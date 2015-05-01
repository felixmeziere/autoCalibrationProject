% Good units script
% a is a CmaesBox object with everything loaded

disp('Freeway entrance link, verified in the pems and in the beats link ids lists :');
c=a.link_ids_beats(logical(a.mainline_mask_beats.*a.source_mask_beats))
c=a.link_ids_pems(logical(a.mainline_mask_pems.*a.source_mask_pems))
disp('Entrance of the freeway corresponds to the first column of the pems data:')
display(ismember(a.link_ids_pems,c));
disp('Entrance of the freeway corresponds to the 160 column of the beats data')
disp(ismember(a.link_ids_beats,c));
disp('Sum of the values in the first column of the pems data divided by 12 :');
d=sum(a.pems.data.flw(:,1))
disp('Sum of the values in the 160 column of the inflow beats data) :');
display(sum(a.beats_simulation.inflow_veh{1,1}(:,160)));
disp('Finally, sum of the template of the entrance link, multiplied by 300 to be in vehicles.');
display(a.get_sum_of_template_in_veh(c));