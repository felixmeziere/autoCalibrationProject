classdef MixedPerformanceCalculator < PerformanceCalculator
    
    properties (SetAccess = protected)
        
        name
        pcs
        weights
        
    end    

    methods (Access = public)
        
        function [obj] = MixedPerformanceCalculator(algoBox,perfStruct) %perfStruct : struct which fields are the names of the performance calculator classes, associated with their respective weight.                
            if (nargin<2)
                npc=input(['Enter the number of different performance calculators that will be involved : ']);
                perfStruct=struct;
                for i=1:npc
                    name=input(['Enter the name of the "PerformanceCalculator" subclass number ', num2str(i),' : '],'s');
                    weight=input(['Enter its weight (sum of weights must be one) : '],'s');
                    eval(strcat('perfStruct.',name,'=',weight,';'));
                end    
            end    
            names=fieldnames(perfStruct);
            for i = 1:size(names,1)
                obj.weights(1,i)=getfield(perfStruct,char(names(i)));
                if (strcmpi(names(i),'CongestionPattern'))
                    obj.pcs{i}=CongestionPattern(algoBox);
                else    
                    obj.pcs{i}=eval(char(names(i)));
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
        
        function [result] = calculate_from_beats(obj,algoBox)
            for i = 1:size(obj.weights,2)
                pc=obj.pcs(i);
                results(i,1)=pc{1}.calculate_from_beats(algoBox);
            end    
            result=obj.weights*results;
            obj.result_from_beats=result;
        end
        
        function [result] = calculate_from_pems(obj, algoBox)
            for i = 1:size(obj.weights,2)
                pc=obj.pcs(i);
                results(i,1)=pc{1}.calculate_from_pems(algoBox);
            end    
            result=obj.weights*results;
            obj.result_from_pems=result;
        end    
            
    end
    
end

