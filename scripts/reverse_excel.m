%reverse excel tab

number=6;
size=4;
array=[1.00
0.75
0.50
0.25
1.00
0.75
0.50
0.25
1.00
0.75
0.50
0.25
1.00
0.75
0.50
0.25
1.00
0.75
0.50
0.25
1.00
0.75
0.50
0.25

];
for i=1:number
    tab((i-1)*4+1:(i-1)*4+4,1)=transpose(flip(array((i-1)*4+1:(i-1)*4+4,1)));
end    
disp(tab);