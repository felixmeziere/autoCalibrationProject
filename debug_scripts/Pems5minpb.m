pointer=ScenarioPtr;
pointer.load('C:\Users\Felix\Desktop\210E_tuesdays.xml');
vds=pointer.get_sensor_vds2id_map;
vds=vds(:,1);
processed='C:\Users\Felix\code\autoCalibrationProject\pems_data\210E\_processed';
days=[datenum('2014/10/14'),datenum('2014/10/21'),datenum('2014/11/18'),datenum('2014/11/25'),datenum('2014/12/16')];



pems=PeMS5minData;
pems.load(processed,vds,days);
pems.get_data_batch_aggregate(vds, days, 'var',{'flw','spd','dty'},'smooth', true, 'fill',true);