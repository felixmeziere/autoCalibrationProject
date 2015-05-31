classdef ErrorFunction <handle
    
    properties (SetAccess = protected)
        
        algorithm_box
        error_calculator@ErrorCalculator % an ErrorCalculator subclass, which is a way of comparing two performance calculator values (e.g. L1 norm).
        performance_calculators  % a cell array containing instances of the PerformanceCalculator subclass, which is a quantity measured in pems or outputed by beats (e.g. TVM).
        weights
        name
        
    end    

    methods (Access = public)
        
        %create object....................................................
        function [obj] = ErrorFunction(algoBox, param) %param : struct which fields are 'performance_calculators', a struct which fields are the names of the performance calculator classes, associated with their respective weight, and 'error_calculator', associated with the name of the error calculator used.               
            obj.algorithm_box=algoBox;
            if (nargin<2)
                param=struct;
            end
            if (~isfield(param,'performance_calculators'))
                npc=input(['Enter the number of different performance calculators that will be involved : ']);
                for i=1:npc
                    name=input(['Enter the name of the "PerformanceCalculator" subclass number ', num2str(i),' : '],'s');
                    weight=input(['Enter its weight (sum of weights must be one) : '],'s');
                    eval(strcat('param.performance_calculators.',name,'=',weight,';'));
                end
            end
            if (~isfield(param,'error_calculator'))
                param.error_calculator=input(['Enter the name of an "ErrorCalculator" subclass (like L1) : ']);
            end
            npc=size(param.performance_calculators,2);
            names=fieldnames(param.performance_calculators);
            obj.error_calculator=param.error_calculator;
            obj.performance_calculators=cell(1,npc);
            for i = 1:size(names,1)
                obj.weights(1,i)=getfield(param.performance_calculators,char(names(i)));
                if (strcmpi(names(i),'CongestionPattern') && isfield(obj.algorithm_box.temp,'congestion_patterns'))
                    obj.performance_calculators{i}=CongestionPattern(obj.algorithm_box, obj.algorithm_box.temp.congestion_patterns);
                else    
                    obj.performance_calculators{i}=eval(strcat(char(names(i)),'(obj.algorithm_box)'));
                end
                if (i==1)
                    obj.name=strcat(num2str(obj.weights(1,i)),'*',names(1));
                else    
                    obj.name=strcat(obj.name,'+', num2str(obj.weights(1,i)),'*',names(i));
                end
            end
            if sum(obj.weights)~=1
                error('The sum of the weights of the performance calculators must be 1.');
            end    
        end
        
        %calculate results................................................
        
        function [] = calculate_pc_from_beats(obj)
            for i=1:size(obj.performance_calculators,2)
                obj.performance_calculators{i}.calculate_from_beats;
            end
        end    
            
        function [] = calculate_pc_from_pems(obj)
             for i=1:size(obj.performance_calculators,2)
                obj.performance_calculators{i}.calculate_from_pems;
             end
        end    
        
        function [result,error_in_percentage] = calculate_error(obj)
            for i=1:size(obj.performance_calculators,2)
                res(i,1)=obj.error_calculator.calculate(obj.performance_calculators{i}.result_from_beats,obj.performance_calculators{i}.result_from_pems);
                errors_in_percentage(i,1)=obj.performance_calculators{i}.error_in_percentage;
            end    
            result=obj.weights*res;
            error_in_percentage=obj.weights*errors_in_percentage;
        end  
            
    end
    
end

