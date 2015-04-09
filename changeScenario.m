function [] = changeScenario(BS, Knobs)
    for i=1:size(Knobs,2)
        BS.scenario_ptr.scenario.DemandSet.demandProfile(Knobs(1,i)).knob = Knobs(2,i);
        BS.scenario_ptr.scenario.DemandSet.demandProfile(Knobs(1,i)).knob 
    end
end
