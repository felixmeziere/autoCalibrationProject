classdef ErrorCalculator<handle
    
    properties (SetAccess = private)
        norm@Norm
        false_positive_coefficient
        false_negative_coefficient
        result
    end    
    
    methods (Access = public)
        
        function [obj] = ErrorCalculator(has_congestion_pattern, norm, false_positive_coefficient, false_negative_coefficient)
            if (nargin < 4)
                if (~exist('has_congestion_pattern','var'))
                    has_congestion_pattern=-1;
                    while(has_congestion_pattern ~=0 && has_congestion_pattern ~=1)
                    has_congestion_pattern=input(['Will CongestionPattern be one of the performance calculators here ? (1=yes,0=no) : ']);
                    end
                end
                if (has_congestion_pattern)
                    norm=input(['Enter the name of a Norm subclass (like L1) : ']);
                    false_negative_coefficient=input([ 'Enter the false negative coefficient for CongestionPattern (zero to one): ']);
                    false_positive_coefficient=input(['Enter the false positive coefficient for CongestionPattern (one-precedent): ']);
                else
                    norm=L1;
                    false_negative_coefficient='NA';
                    false_positive_coefficient='NA';
                end
            end
            if (~(strcmp(false_negative_coefficient,'NA') || strcmp(false_positive_coefficient,'NA')) && false_negative_coefficient+false_positive_coefficient~=1)
               error('The sum of the false positive and false negative coefficients must be one.')
            end
            obj.norm=norm;
            obj.false_positive_coefficient=false_positive_coefficient;
            obj.false_negative_coefficient=false_negative_coefficient;
        end    

        function [result,result_in_percentage] = calculate(obj, beatsPerformance, pemsPerformance)
            if (size(beatsPerformance,1)~=1 && size(beatsPerformance,2)~=1)
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
            else
                result=obj.norm.calculate(beatsPerformance,pemsPerformance);
                result_in_percentage=result/pemsPerformance;
            end
            obj.result = result;
        end
        
    end
    
end
