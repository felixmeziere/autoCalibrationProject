classdef (Abstract) PerformanceCalculator < handle
    %PerformanceCalculator Summary of this class goes here
    %   Detailed explanation goes here
   properties (SetAccess = protected)
       result_from_beats
       result_from_pems
   end
   
   methods(Abstract, Static, Access = public)
        [result] = calculate_from_beats(obj, BS)
        [result] = calculate_from_pems(obj, Pems)   
   end
end

