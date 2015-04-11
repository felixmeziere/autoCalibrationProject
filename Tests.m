a= BeatsSimulation;
b= BeatsSimulation;
a.load_scenario('C:\Users\Felix\code\RealScenario.xml');
b.load_scenario('C:\Users\Felix\code\purchiotcom.xml');
a.run_beats;
b.run_beats;
c=algorithmBox;
c.knobs.knob_ids = [2,4];
c.knobs.knob_boundaries = [1,1;5,5];
c.beats_simulation=a;
c.pemsScenario=b;
d=cmaesAlgorithm(c.knobs);
d.initial_population=[2;5];
e=errorFunctionBox(TVM, L1, d.knobs.knob_ids, 'DURATION=86000', a,b);
d.errorFunctionBox=e;
c.algorithm=d;






