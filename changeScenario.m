function [] = changeScenario(BS, knobs)
    for i=1:size(knobs,2)
        BS.scenario_ptr.scenario.DemandSet.demandProfile(knobs(1,i)).knob = knobs(2,i); 
    end
end
