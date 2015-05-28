g=zeros(size(a.linear_link_ids));
g(ismember(a.linear_link_ids,a.link_ids_beats(a.good_mainline_mask_beats)))=1;
g(ismember(a.linear_link_ids,a.knobs.knob_link_ids))=-1;

imagesc(g);
