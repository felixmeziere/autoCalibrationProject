g=zeros(size(a.linear_link_ids)); %green
g(ismember(a.linear_link_ids,a.link_ids_beats(a.good_mainline_mask_beats)))=2; %yellow
g(ismember(a.linear_link_ids,a.knobs.link_ids))=-1; %blue
g(ismember(a.linear_link_ids,a.link_ids_beats(logical(a.good_source_mask_beats+a.good_sink_mask_beats))))=1; %beige

figure
imagesc(g)
