classdef CongestionError < ErrorCalculator

    properties (Constant)
        name='Congestion error';
    end
    
    properties (SetAccess = private)
        norm
        norm_name
        false_positive_coefficient
        false_negative_coefficient
    end    
    
    methods (Access = public)
        
        function [obj] = CongestionError(normErrorCalculator, false_positive_coefficient, false_negative_coefficient)
            obj.norm=normErrorCalculator;
            obj.norm_name=obj.norm.name;
            obj.false_positive_coefficient=false_positive_coefficient;
            obj.false_negative_coefficient=false_negative_coefficient;
        end    

        function [result] = calculate(obj, beatsPerformance, pemsPerformance)
            contour=pemsPerformance-beatsPerformance;
            for i=1:size(contour,2)
                for j=1:size(contour,1)
                    if contour(j,i)==1
                        contour(j,i)=obj.false_negative_coefficient;
                    elseif contour(j,i)==-1
                        contour(j,i)=obj.false_positive_coefficient;
                    end    
                end
            end
            result=obj.norm.calculate(contour,0);
            obj.result = result;
        end
        
    end
    
end
