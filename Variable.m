classdef (Abstract) Variable < handle
    
    properties(Abstract, Constant)
        name
    end    

    properties (SetAccess=protected)
       
        is_loaded=0;
        
        dimension
        boundaries_min
        boundaries_max
        
        current_value
        history
        genmean_history
        zeroten_history
        zeroten_genmean_history
        
    end
    
    properties (Access=protected)
        
        algorithm_box@AlgorithmBox
        
    end    
    
    methods (Abstract, Access=public)
    
        [] = run_assistant(obj)
        
        [] = ask_for_boundaries(obj)
        
    
    end
    
    methods (Abstract, Access=?AlgorithmBox)
        
        [] = set_persistent(obj, values_vector)
        
        [] = set_auto_boundaries(obj)
        
        [] = reset_history(obj)
        
    end
    
    methods (Access=public)
    
        function [] = plot_all_history(obj)
        end
        
        function [] = plot_all_genmean_history(obj)
        end
        
        function [] = plot_all_zeroten_history(obj,figureNumber, evaluation_number)
            n=nargin;
            if (n<2)
                h=figure;
            else
                h=figure(figureNumber);
            end  
            if n>2 && evaluation_number<size(obj.zeroten_history,1)
                zeroten_history=obj.zeroten_history(1:evaluation_number,:);
            else    
                zeroten_history=obj.zeroten_history;
            end    
%                     p=[700,400,800,470];
%                     set(h, 'Position', p);
            plot(zeroten_history);
            title([obj.name,' rescaled to 0-10 evolution']);
            xlabel('Number of BEATS evaluations');
            ylabel('0-10 values');  
        end
            
        function [] = plot_all_zeroten_genmean_history(obj,figureNumber, evaluation_number)
            n=nargin;
            if (n<2)
                h=figure;
            else
                h=figure(figureNumber);
            end  
            if n>2 && evaluation_number<size(obj.zeroten_history,1)
                zeroten_genmean_history=obj.zeroten_genmean_history(1:evaluation_number,:);
            else    
                zeroten_genmean_history=obj.zeroten_genmean_history;
            end    
%                     p=[700,400,800,470];
%                     set(h, 'Position', p);
            plot(zeroten_genmean_history);
            title([obj.name,' rescaled to 0-10 generation mean evolution']);
            xlabel('Number of BEATS evaluations');
            ylabel('0-10 values');  
        end
    
    end
    
    methods (Access=protected)
        
        function [result_matrix] = rescale(obj, input_matrix, isRealScaleToZeroTenScale
            min=repmat(obj.boundaries_min,1,size(input_matrix,2));
            range=repmat(obj.boundaries_max-obj.boundaries_min,1,size(input_matrix,2));
            if isRealScaleToZeroTenScale==1
                result_matrix=((input_matrix-min)./range)*10;
            elseif isRealScaleToZeroTenScale==0
                result_matrix=((input_matrix/10).*range)+min;
            else error ('The second parameter must be zero or one');
            end  
        end    
    
    end    

end

