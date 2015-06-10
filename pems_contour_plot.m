%b is a loaded CmaesBox

mask=b.send_mask_pems_to_linear_mainline_space(b.good_mainline_mask_pems);
linear_mainline=b.send_mask_pems_to_linear_space(b.good_mainline_mask_pems);
ids=b.pems.linear_link_ids(linear_mainline);
ids=unique(ids,'stable');
for i=1:36
    ordered_indices(1,i)=find(b.pems.link_ids(b.good_mainline_mask_pems)==ids(1,i));
end
data=b.pems.data.flw_in_veh(:,ordered_indices);
count=1;
for i=1:135
    if mask(i)==1
        toplot(:,i)=data(:,count);
    else
        toplot(:,i)=0;
    end
end
imagesc(toplot);
title('PeMS DATA CONTOUR PLOT FOR 210E on 10/01/2014');
