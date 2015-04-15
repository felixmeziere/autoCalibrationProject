classdef (Abstract) ErrorCalculator < handle
    %ErrorCalculator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract, Constant)
        name
    end
    
    properties (SetAccess=protected)
        result
    end
    
   
    methods (Abstract, Access = public)
        [result] = calculate(obj, beatsPerformance, pemsPerformance)
    end       
end

