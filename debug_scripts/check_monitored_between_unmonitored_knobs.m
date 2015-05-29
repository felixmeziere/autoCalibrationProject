g=zeros(size(a.linear_link_ids)); %green
g(ismember(a.linear_link_ids,a.link_ids_beats(a.good_mainline_mask_beats)))=200; %yellow
g(ismember(a.linear_link_ids,a.knobs.knob_link_ids))=-100; %blue
% g(ismember(a.linear_link_ids,a.link_ids_beats(logical(a.good_source_mask_beats+a.good_sink_mask_beats))))=100; %beige

imagesc(g)
