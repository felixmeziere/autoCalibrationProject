classdef Utilities
    
    methods (Static, Access = public)
        function [char] = double2char(double) %a way to serialize an array
            s1 = size(double,1);
            s2= size(double,2);
            char='[';
            for i=1:s1-1
                for k = 1:s2-1
                    char=strcat(char,num2str(double(i,k)),',');
                end
                char=strcat(char,num2str(double(i,s2)),';');
            end
            for k = 1:s2-1
                    char=strcat(char,num2str(double(s1,k)),',');
            end
            char=strcat(char,num2str(double(s1,s2)),']');
        end    
    end
    
end

