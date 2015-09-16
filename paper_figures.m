%Save svg figures generation average knobs for the last 9 'unicity & popsize
%influence' runs.

% directory='cmaes_reports\';
% dates=cell(1,3);
% dates={'18-Jul-2015','19-Jul-2015','20-Jul-2015'};
% 
% for j=1:size(dates,2)
%     for i=1:3
%         dated_name=[dates{j},'_',num2str(i)];
%         load([directory,dated_name,'\',dated_name,'_allvariables']);
%         close all
%         obj.knobs.plot_zeroten_knobs_genmean_history(1);
%         figure(1);
%         print(['paper_figures\',dated_name,'_genmean_knobs'],'-dsvg');
%         clear obj
%     end   
% end        





%Save svg figures congestion pattern for the last 9 'unicity & popsize
%influence' runs.

% directory='cmaes_reports\';
% dates={'18-Jul-2015','19-Jul-2015','20-Jul-2015'};
% 
% for j=1:size(dates,2)
%     for i=1:3
%         dated_name=[dates{j},'_',num2str(i)];
%         load([directory,dated_name,'\',dated_name,'_allvariables']);
%         close all
%         obj.plot_performance_calculator_if_exists('CongestionPattern');
%         figure(1);
%         print(['paper_figures\',dated_name,'_cp'],'-dsvg');
%         clear obj
%     end   
% end        





% % % Set up cmaes objects in objs for the runs in dates.
% 
% directory='cmaes_reports\';
% dates={'09-Jul-2015_1','10-Jul-2015_1','10-Jul-2015_2','10-Jul-2015_4','11-Jul-2015_1','11-Jul-2015_2','11-Jul-2015_3','11-Jul-2015_4','11-Jul-2015_5','12-Jul-2015_1',...
% '12-Jul-2015_2','12-Jul-2015_3','12-Jul-2015_4','12-Jul-2015_5','13-Jul-2015_1','13-Jul-2015_2','14-Jul-2015_1','14-Jul-2015_2','15-Jul-2015_1',...
% '16-Jul-2015_1','16-Jul-2015_2','17-Jul-2015_1','17-Jul-2015_2','17-Jul-2015_3','18-Jul-2015_1','18-Jul-2015_2','18-Jul-2015_3','19-Jul-2015_1','19-Jul-2015_2','19-Jul-2015_3','20-Jul-2015_1','20-Jul-2015_2','20-Jul-2015_3'};
% 
% objs={};
% for j=1:size(dates,2)
%     dated_name=dates{j};
%     load([directory,dated_name,'\',dated_name,'_allvariables']);
%     close all
%     objs{1,j}=obj;
%     clear obj
% end        
% 
% % dates groups
% 
% Umul_100={'09-Jul-2015_1','11-Jul-2015_1','11-Jul-2015_5','12-Jul-2015_4','14-Jul-2015_1','16-Jul-2015_2'};
% Umul_75={'10-Jul-2015_1','11-Jul-2015_2','12-Jul-2015_1','12-Jul-2015_5','14-Jul-2015_2','17-Jul-2015_1'};
% Umul_50={'10-Jul-2015_2','11-Jul-2015_3','12-Jul-2015_2','13-Jul-2015_1','15-Jul-2015_1','17-Jul-2015_2'};
% Umul_25={'10-Jul-2015_4','11-Jul-2015_4','12-Jul-2015_3','13-Jul-2015_2','16-Jul-2015_1','17-Jul-2015_3'};
% 
% Uadd_25=flip({'12-Jul-2015_4','12-Jul-2015_5','13-Jul-2015_1','13-Jul-2015_2','09-Jul-2015_1','10-Jul-2015_1','10-Jul-2015_2','10-Jul-2015_4'});
% Uadd_5=flip({'14-Jul-2015_1','14-Jul-2015_2','15-Jul-2015_1','16-Jul-2015_1','11-Jul-2015_1','11-Jul-2015_2','11-Jul-2015_3','11-Jul-2015_4'});
% Uadd_10=flip({'16-Jul-2015_2','17-Jul-2015_1','17-Jul-2015_2','17-Jul-2015_3','11-Jul-2015_5','12-Jul-2015_1','12-Jul-2015_2','12-Jul-2015_3'});
% 
% lambda_12={'18-Jul-2015_1','18-Jul-2015_2','18-Jul-2015_3'};
% lambda_24={'19-Jul-2015_1','19-Jul-2015_2','19-Jul-2015_3'};
% lambda_36={'20-Jul-2015_1','20-Jul-2015_2','20-Jul-2015_3'};
% lambda_0=[lambda_12,lambda_24,lambda_36];







% 
% % % Subplot knobs for knobs_dates
% knobs_dates=[uadd_big];
% % knobs_dates={'09-Jul-2015_1','11-Jul-2015_1','11-Jul-2015_5','12-Jul-2015_4','14-Jul-2015_1','16-Jul-2015_2'};
% % knobs_dates={'11-Jul-2015_2'};
% close all;
% h=figure;
% for j=1:size(knobs_dates,2)
%     dated_name=knobs_dates{j};
%     for i=1:size(dates,2)
%         if strcmp(dates{1,i},dated_name);
%             obj=objs{1,i};
%         end    
%     end    
%     subplot(2,4,j);
%     obj.knobs.plot_zeroten_knobs_history;
% %     h=figure(j);
% %     h.Name=dated_name;
% %     set(gca,'fontsize',15);
%     title(['\sigma=',num2str(obj.insigma), ' | ', 'U_m_u_l=',num2str((obj.knobs.overevaluation_tolerance_coefficient-1)*100),'%']);
% end    
% h.Name='knobs_Uadd_10_lambda_11';
% savefig(h,['C:\Users\felix\code\knobs\figures\results_figures\uadd\',h.Name,'.fig']);


%Save Congestion pattern and knobs subplots

% prefix='lambda';
% values=[12,24,36];
% form=[1,3];
% 
% 
% for i=1:size(values,2)  
%     cp_dates=eval([prefix,'_',num2str(values(i))]);
%     close all;
%     for j=1:size(cp_dates,2)
%         dated_name=cp_dates{j};
%         for k=1:size(dates,2)
%             if strcmp(dates{1,k},dated_name);
%                 obj=objs{1,k};
%             end    
%         end    
%         h=figure(1);
%         subplot(form(1),form(2),j);
%         obj.error_function.plot_performance_calculator_if_exists('CongestionPattern');
% %         title(['\sigma=',num2str(obj.insigma),' | ','U_m_u_l=',num2str((obj.knobs.overevaluation_tolerance_coefficient-1)*100),'%',' | ', 'E_c_p=',num2str(round(obj.error_function.performance_calculators{1}.error_in_percentage,1)),'%']);
% %         title(['\sigma=',num2str(obj.insigma),' | ','U_a_d_d=',num2str(obj.pems.mainline_uncertainty*100),'%',' | ', 'E_c_p=',num2str(round(obj.error_function.performance_calculators{1}.error_in_percentage,1)),'%']);
%             title(['\lambda=',num2str(obj.population_size),' | ', 'E_c_p=',num2str(obj.error_function.performance_calculators{1}.error_in_percentage),'%']);
%         set(gca,'fontsize',13);
%         l=figure(2);
%         subplot(form(1),form(2),j);
% %         obj.knobs.plot_zeroten_knobs_history;
%         obj.knobs.plot_zeroten_knobs_genmean_history;
%         set(gca,'fontsize',13);
%         title(['\sigma=',num2str(obj.insigma), ' | ', 'U_m_u_l=',num2str((obj.knobs.overevaluation_tolerance_coefficient-1)*100),'%']);
% %         title(['\sigma=',num2str(obj.insigma),' | ','U_a_d_d=',num2str(obj.pems.mainline_uncertainty*100),'%']);
%         title(['\lambda=',num2str(obj.population_size)]);
%         
%     end    
% %      h.Name=['cp_',prefix,'_',num2str(values(1,i)),'_lambda_11'];
% %      l.Name=['knobs_',prefix,'_',num2str(values(1,i)),'_lambda_11'];
% %      h.Name=['cp_lambda_',num2str(obj.population_size)];
% %      l.Name=['knobs_lambda_',num2str(obj.population_size)];
% %      l.Name=['knobs_lambda_',num2str(obj.population_size),'_genmean'];
% %      h.Name=['cp_lambda_all'];
% %      l.Name=['knobs_lambda_all'];
% %      l.Name=['knobs_lambda_all_genmean'];
%      savefig(h,['C:\Users\felix\code\knobs\figures\results_figures\',prefix,'\',h.Name,'.fig']);
%      savefig(l,['C:\Users\felix\code\knobs\figures\results_figures\',prefix,'\',l.Name,'.fig']);
% end     



% % Plot cp for the same 24 runs
% close all;
% for j=1:size(dates,2)
%     dated_name=dates{j};
%     objs{1,j}.error_function.plot_performance_calculator_if_exists('CongestionPattern');
%     h=figure(j);
%     h.Name=dated_name;
%     title(objs{1,j}.dated_name);
%     legend OFF
% end    





% Plot beats contour and cp for the cp_dates runs among the 24.
% close all;
% cp_dates={'09-Jul-2015_1','11-Jul-2015_1','11-Jul-2015_5','12-Jul-2015_4','14-Jul-2015_1','16-Jul-2015_2'};
% % cp_dates={'13-Jul-2015_2'};
% % cp_dates=dates;
% for j=1:size(cp_dates,2)
%     dated_name=cp_dates{j};
%     for i=1:size(dates,2)
%         if strcmp(dates{1,i},dated_name);
%             obj=objs{1,i};
%         end    
%     end    
%     obj.beats_simulation.plot_freeway_contour;
%     h=figure(4*(j-1)+1);
%     h.Name=dated_name;
%     ylabel('Time-steps');
%     xlabel('Mainline links (linear order)');
%     colormap('Jet');
%     title('Density contour plot (veh/mile)');
%     set(h.Children(2),'fontsize',15);
%     h=figure(4*(j-1)+2);
%     h.Name=dated_name;
% %     close h;
%     h=figure(4*(j-1)+3);
%     h.Name=dated_name;
% %     close h;
%     obj.error_function.plot_performance_calculator_if_exists('CongestionPattern');
%     h=figure(4*(j-1)+4);
%     h.Name=dated_name;
%     set(h.Children(2),'fontsize',15);
% end    
    

% %open all files in a folder
% 
% dirname='C:\Users\felix\code\knobs\figures\results_figures\';
% subdirname='umul';
% dirsubdirname=[dirname,subdirname,'\'];
% directory=dir(dirsubdirname);
% for i=3:size(directory,1)
%     open([dirsubdirname,directory(i).name]);
% end    


close all
% save all files in a different format
dirname='C:\Users\felix\code\knobs\figures\results_figures\';
subdirname=prefix;
dirsubdirname=[dirname,subdirname,'\'];
directory=dir(dirsubdirname);
for i=3:size(directory,1)
    [~,name,ext]=fileparts(directory(i).name);
    if strcmp(ext,'.fig')
        fig=open([dirsubdirname,directory(i).name]);
        fig.Position=[0,0,1366,768];
        frame=getframe(fig);
        im=frame2im(frame);
        imwrite(im,[dirsubdirname,name,'.png'],'png');
        close all
    end
end    