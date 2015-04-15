% Single run of the algorithm set manually.

a=CmaesAlgorithmBox;
a.run_assistant; %Please enter the scenartiototest.xml file adress as scenario for beats.
a.pems=BeatsSimulation;
a.pems.load_scenario('C:\Users\Felix\code\autoCalibrationProject\pemsdata.xml');
a.pems.run_beats; % these three last lines are to replace what will be the pems data : 
%for now, it is the result of a beats simulation and I compare the results on every link of the mainlink.
%Therefore, here, the scenario pemsdata is the same as for the beats simulation entered above,
%the best answer for the algorithm (error function = 0) is all the knobs set to 1.
a.run_algorithm;
a.plot;

% Single run of the algorithm set by the second column of an Excel file.

% a=CmaesAlgorithmBox;
% a.load_xls('C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_program.xlsx');
% a.pems=BeatsSimulation;
% a.pems.load_scenario('C:\Users\Felix\code\autoCalibrationProject\pemsdata.xml');
% a.pems.run_beats; % these three last lines are to replace what will be the pems data : 
% %for now, it is the result of a beats simulation and I compare the results on every link of the mainlink.
% %Therefore, here, the scenario pemsdata is the same as for the beats simulation entered above,
% %the best answer for the algorithm (error function = 0) is all the knobs set to 1. 
% a.run_algorithm;
% a.plot;



% %Run program set in Excel file, from columns 2 to 4, and print the results in another one.
% 
% a=CmaesAlgorithmBox;
% a.load_xls('C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_program.xlsx','C:\Users\Felix\code\autoCalibrationProject\xls\Results.xlsx');
% a.pems=BeatsSimulation;
% a.pems.load_scenario('C:\Users\Felix\code\autoCalibrationProject\pemsdata.xml');
% a.pems.run_beats; % these three last lines are to replace what will be the pems data : 
% %for now, it is the result of a beats simulation and I compare the results on every link of the mainlink.
% %Therefore, here, the scenario pemsdata is the same as for the beats simulation entered above,
% %the best answer for the algorithm (error function = 0) is all the knobs set to 1. 
% a.run_program(2,4);