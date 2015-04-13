% a= BeatsSimulation;
% b= BeatsSimulation;
% a.load_scenario('C:\Users\Felix\code\RealScenario.xml');
% b.load_scenario('C:\Users\Felix\code\purchiotcom.xml');
% a.run_beats;
% b.run_beats;
c=CmaesAlgorithmBox;
c.knobs.knob_ids = [2,4];
c.knobs.knob_boundaries = [1,1;5,5];
c.beats_simulation=a;
c.beats_parameters.SIM_DT=5;
c.beats_parameters.OUTPUT_DT = 60;
c.pems=b;
c.initial_population=[2,4;3,2];
c.error_calculator=L1;
c.performance_calculator=TVM;






