a= BeatsSimulation;
b= BeatsSimulation;
a.load_scenario('C:\Users\Felix\code\RealScenario.xml');
b.load_scenario('C:\Users\Felix\code\purchiotcom.xml');
a.run_beats;
b.run_beats;
c=algorithmBox;
c.knobs.knobs_id = [2,4];
c.knobs.knobs_boundaries = [1,1;5,5];
d=cmaesAlgorithm(c.knobs);
d.initial_population=[2;5];
e=fitnessFunctionBox(TVM, L1, d.knobs.knobs_id, 'DURATION=86000', a,b);





