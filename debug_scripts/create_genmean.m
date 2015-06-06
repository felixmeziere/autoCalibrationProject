dirname=[pwd,'\movies\'];
list=dir(dirname);
for j=3:size(list,1)
    load([pwd,'\cmaes_reports\',list(j).name,'\',list(j).name,'_allvariables.mat']);
    nknobs=size(obj.knobs.link_ids,1);
    obj.error_function.result_genmean_history=[];
    obj.knobs.zeroten_knobs_genmean_history=[];
    for i=1:obj.numberOfEvaluations
        if i<=size(obj.knobs.zeroten_knobs_history,1)
            last=i-mod(i,nknobs);
            if (last<=obj.numberOfEvaluations-nknobs)
                obj.knobs.zeroten_knobs_genmean_history(end+1,1:nknobs)=mean(obj.knobs.zeroten_knobs_history(last+1:last+nknobs,1:nknobs),1);
                obj.error_function.result_genmean_history(end+1,1)=mean(obj.error_function.result_history(last+1:last+nknobs,1),1);
            else
                obj.knobs.zeroten_knobs_genmean_history(end+1,1:nknobs)=mean(obj.knobs.zeroten_knobs_history(last+1-nknobs:last,1:nknobs),1);
                obj.error_function.result_genmean_history(end+1,1)=mean(obj.error_function.result_history(last+1-nknobs:last,1),1);
            end    
        end     
    end
    zeroten_knobs_genmean_history=obj.knobs.zeroten_knobs_genmean_history;
    result_genmean_history=obj.error_function.result_genmean_history;
    save([pwd,'\movies\',list(j).name,'\','zeroten_knobs_genmean_history.mat'],'zeroten_knobs_genmean_history');
    save([pwd,'\movies\',list(j).name,'\','result_genmean_history.mat'],'result_genmean_history');
    save([pwd,'\cmaes_reports\',list(j).name,'\',list(j).name,'_allvariables.mat']);
end