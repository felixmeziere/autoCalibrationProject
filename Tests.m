rectangles=cell(2,1);
d.left_absciss=1;
d.right_absciss=10;
d.up_ordinate=1;
d.down_ordinate=12;
e.left_absciss=40;
e.right_absciss=100;
e.up_ordinate=144;
e.down_ordinate=210;
rectangles{1,1}=d;
rectangles{2,1}=e;
b= CongestionPattern(a,rectangles); 
b.calculate_from_beats(a);
b.calculate_from_pems(a);
d=-b.result_from_beats+b.result_from_pems;
imagesc(d)
    