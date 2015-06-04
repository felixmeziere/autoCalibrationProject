classdef ErrorFunction < handle
    
    properties (SetAccess = ?AlgorithmBox)
        
        is_loaded=0;
        algorithm_box
        error_calculator@ErrorCalculator % an ErrorCalculator subclass, which is a way of comparing two performance calculator values (e.g. L1 norm).
        performance_calculators  % a cell array containing instances of the PerformanceCalculator subclass, which is a quantity measured in pems or outputed by beats (e.g. TVM).
        weights_and_exponents
        name
        result
        results
        transformed_results
        error_in_percentage
        result_history % consecutive values of the errorFunction during last run

    end    

    methods (Access = public)
        
        %create object.....................................................
        function [obj] = ErrorFunction(algoBox, param) %param : struct which fields are 'performance_calculators', a struct which fields are the names of the performance calculator classes, associated with their respective weight and exponent, and 'error_calculator', associated with the name of the error calculator used.               
            first_time=1;
            obj.algorithm_box=algoBox;
            if (obj.algorithm_box.beats_loaded==1 && obj.algorithm_box.pems.is_loaded==1 && obj.algorithm_box.masks_loaded==1)
                if (nargin<2)
                    param=struct;

                end
                has_congestion_pattern=0;
                if (~isfield(param,'performance_calculators'))
                    param.performance_calculators=struct;
                    npc=input(['Enter the number of different performance calculators that will be involved : ']);
                    for i=1:npc
                        name=input(['Enter the name of the "PerformanceCalculator" subclass number ', num2str(i),' (like TVH) : '],'s');
                        weight=input(['Enter its weight (sum of weights must be one) : ']);
                        exponent=input('Enter its exponent : ');
                        param.performance_calculators=setfield(param.performance_calculators,name,[weight,exponent]);
                        if strcmp(name,'CongestionPattern')
                            has_congestion_pattern=1;
                        end    
                    end
                end
                if (~isfield(param,'error_calculator'))
                    param.error_calculator=ErrorCalculator(has_congestion_pattern);
                end
                npc=size(param.performance_calculators,2);
                names=fieldnames(param.performance_calculators);
                obj.error_calculator=param.error_calculator;
                obj.performance_calculators=cell(1,npc);
                for i = 1:size(names,1)
                    weight_and_exponent=getfield(param.performance_calculators,char(names(i)));
                    obj.weights_and_exponents(1,i)=weight_and_exponent(1);
                    obj.weights_and_exponents(2,i)=weight_and_exponent(2);
                    if strcmpi(names(i),'CongestionPattern') 
                        if isfield(obj.algorithm_box.temp,'congestion_patterns')
                            first_time=0;
                            change_rectangles=-1;
                            if (nargin<2)
                                while (change_rectangles~=1 && change_rectangles ~= 0)
                                    change_rectangles=input(['Do you want to change the rectangles (instead of leaving them as they were until now) (1=yes/0=no) ? : ']);
                                end
                            end    
                            if change_rectangles==1
                                obj.algorithm_box.remove_field_from_property('temp','congestion_patterns');
                                obj.performance_calculators{i}=CongestionPattern(obj.algorithm_box);
                                obj.algorithm_box.temp.congestion_patterns=obj.performance_calculators{i}.rectangles;
                            else    
                                obj.performance_calculators{i}=CongestionPattern(obj.algorithm_box, obj.algorithm_box.temp.congestion_patterns);
                            end
                        else
                            obj.performance_calculators{i}=CongestionPattern(obj.algorithm_box);
                            obj.algorithm_box.temp.congestion_patterns=obj.performance_calculators{i}.rectangles;
                        end
                    else    
                        obj.performance_calculators{i}=eval(strcat(char(names(i)),'(obj.algorithm_box)'));
                    end
                    if (i==1)
                        obj.name=strcat('(',num2str(obj.weights_and_exponents(1,i)),'*',names(1),')','^',num2str(obj.weights_and_exponents(2,i)));
                    else    
                        obj.name=strcat(obj.name,'+', '(', num2str(obj.weights_and_exponents(1,i)),'*',names(i),')','^',num2str(obj.weights_and_exponents(2,i)));
                    end
                    obj.name=char(obj.name);
                end
                if sum(obj.weights_and_exponents(1,:))~=1
                    error('The sum of the weights of the performance calculators must be 1.');
                end
                if (nargin<2 && first_time==0)
                    obj.algorithm_box.reset_beats;
                end    
                obj.calculate_pc_from_beats;
                obj.calculate_pc_from_pems;
                obj.calculate_error;  
                obj.is_loaded=1;
            else
                error('Beats Simulation and Pems data must be loaded first.')
            end
        end
        
        %calculate results.................................................
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
                res(i,1)=(obj.error_calculator.calculate(obj.performance_calculators{i}.result_from_beats,obj.performance_calculators{i}.result_from_pems));
                errors_in_percentage(i,1)=obj.performance_calculators{i}.error_in_percentage;
            end
            obj.transformed_results=(obj.weights_and_exponents(1,:).*(transpose(res)).^obj.weights_and_exponents(2,:));
            result=sum(obj.transformed_results);
            error_in_percentage=obj.weights_and_exponents(1,:)*errors_in_percentage;
            obj.result=result;
            obj.results=res;
            obj.error_in_percentage=error_in_percentage;
        end  
        
        %plot functions...................................................
        function [] = plot_performance_calculator_if_exists(obj,performance_calculator, figureNumber)  
            index=obj.find_performance_calculator(performance_calculator);
            if (index~=0)
                if (nargin<3)
                    obj.performance_calculators{index}.plot;
                else    
                    obj.performance_calculators{index}.plot(figureNumber);
                end
            end
        end 
        
        function [] = plot_result_history(obj, figureNumber, result_history, evaluation_number)
            n=nargin;
            if (n<2)
                h=figure;
            else    
                h=figure(figureNumber);
            end
            if (n==4)
                result_history=result_history(1:evaluation_number,1);
            else
                if (n~=3)
                    result_history=obj.result_history;
                    p=[30,400,700,470];
                    set(h, 'Position', p);
                end    
            end    
            plot(result_history(:,1));
            title('Error function evolution');
            xlabel('Number of BEATS evaluations');
            ylabel('Error function value');
        end
        
        function [] = plot_all_performance_calculators(obj,starting_index)
            if (nargin<2)
                for i=1:size(obj.performance_calculators,2)
                    obj.performance_calculators{i}.plot;
                end 
            else
                for i=1:size(obj.performance_calculators,2)
                    obj.performance_calculators{i}.plot(i+starting_index-1);
                end    
            end    
        end    
        
    end
    
    methods (Access = ?AlgorithmBox)
    
        function [index] = find_performance_calculator(obj,performance_calculator_name)
            index=0;
            for i=1:size(obj.performance_calculators,2)
                if (strcmp(class(obj.performance_calculators{i}),performance_calculator_name))
                    index=i;
                end    
            end
            if index==0
                string=['Sorry, no ',performance_calculator_name,' among the performance calculators of this error function.'];
                disp(string);
            end    
        end    
        
        function [] = reset_for_new_run(obj)
            obj.result_history=[];
            for i=1:size(obj.performance_calculators,2)
                obj.performance_calculators{1,i}.error_in_percentage_history=[];
            end    
        end    
        
    end
    
end

