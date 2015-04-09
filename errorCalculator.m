classdef (Abstract) errorCalculator < handle
    %errorCalculator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        result
    end
    
   
    methods (Abstract, Access = public)
        [result] = calculate(obj, beatsPerformance, pemsPerformance)
    end       
end

