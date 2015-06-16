
for i=1:size(a.knobs.knob_groups,2)
    disp(['kg',num2str(i)]);
    for j=1:size(a.knobs.knob_groups{1,i},1)
        disp(find(a.knobs.link_ids==cell2mat(a.knobs.knob_groups{1,i}(j,1))));
    end
end    