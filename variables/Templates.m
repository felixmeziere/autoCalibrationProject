classdef Templates < Variable
    
    properties(Constant)
        
        name='Knobs and templates relative importance coefficients'
        
    end    
    
    properties %(SetAccess=?AlgorithmBox)
        
        knobs@KnobsExperimental
        template_base
        n_bad_ramps
        link_ids
        
        naive_boundaries_min
        naive_boundaries_max
        
    end
    
    properties(Access=protected)
        
        base_dimension
        
        pre_template_projection_value
        
    end    
    
    methods(Access = public)
        
        [] = run_assistant(obj)
        
        [] = ask_for_boundaries(obj)
        
        function [obj] = Templates(algoBox)
            obj.algorithm_box=algoBox;
            obj.link_ids=obj.algorithm_box.link_ids_beats(logical((~obj.algorithm_box.good_source_mask_beats+~obj.algorithm_box.good_sink_mask_beats).*obj.mainline_mask_beats));
            obj.n_bad_ramps=length(obj.link_ids);
            if ~isfield(obj.algorithm_box.settings,'template_base') || size(obj.algorithm_box.settings.template_base,1)==0
                obj.run_assistant;
            else
                obj.template_base=obj.algorithm_box.settings.template_base;
            end    
            obj.base_dimension=size(obj.template_base,2);
            for i=1:obj.base_dimension
                sum_of_template=sum(obj.template_base(:,i));
                obj.template_base(:,i)=obj.template_base(:,i)*5000/sum_of_template;
            end    
            obj.knobs=KnobsExperimental(obj.algorithm_box,obj);
        end    
        
    end
    
    methods (Access=?AlgorithmBox)
        
        function [] = set_persistent(obj, values_vector)
            values_vector=obj.normalize_template_coefficients(values_vector);
            for i=1:obj.n_bad_ramps
                link_id=obj.link_ids(i,1);
                index=(i-1)*(obj.base_dimension+1);
                knob=index+1;
                for j=1:obj.base_dimension
                    coeffs(1,j)=values_vector(index+1+j,1);
                end    
                profile=obj.template_base*transpose(coeffs);
                obj.algorithm_box.beats_simulation.beats.set_template_for_link_id(link_id,profile);
                obj.knobs.set_knobs_persistent(link_id, knob);
                obj.current_value=values_vector;
                obj.history(end+1,:)=obj.current_value;
                obj.zeroten_history(end+1,:)=rescale(obj.current_value,1);
            end    
        end
        
        function [] = set_auto_boundaries(obj)
            obj.is_loaded=0;
            for i=1:obj.n_bad_ramps
                index=(i-1)*(obj.base_dimension+1);
                obj.boundaries_min(index+2:index+obj.base_dimension,1)=0;
                obj.boundaries_max(index+2:index+obj.base_dimension,1)=1;
                obj.knobs.set_auto_knob_boundaries;
                obj.boundaries_min(index+1,1)=obj.knobs.boundaries_min(i,1);
                obj.boundaries_max(index+1,1)=obj.knobs.boundaries_max(i,1);
            end    
            obj.is_loaded=1;
        end    
        
        function [] = reset_history(obj)
            obj.history=[];
            obj.genmean_history=nan;
            obj.zeroten_history=[];
            obj.zeroten_genmean_history=nan;
        end    
        
        function [normalized_values_vector] = normalize_template_coefficients(obj, values_vector)
            obj.pre_template_projection_value=values_vector;
            for i=1:obj.n_bad_ramps
                index=(i-1)*obj.base_dimension;
                subvector=values_vector(index+2:index+1+obj.base_dimension,1);
                values_vector(i+2:i+1+obj.base_dimension)=subvector*1/sum(subvector);
            end    
            normalized_values_vector=values_vector;
        end    
    
    end    
    
    
end

