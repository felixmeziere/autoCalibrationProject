classdef Utilities
    
    methods (Static, Access = public)
        
        function [char] = double2char(double) %a way to serialize an array
            char='';
            if isa(double,'double')
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
        
        function [char] = charArray2char(charArray) %transform a (n x p) characters array into an (1 x m) one.
            s1 = size(charArray,1);
            s2= size(charArray,2);
            char='[';
            for i=1:s1-1
                for k = 1:s2-1
                    char=strcat(char,char(charArray(i,k)));
                end
                char=strcat([char,char(charArray(i,s2)),';']);
            end
            for k = 1:s2-1
                    char=strcat(char,char(charArray(s1,k)));
            end
            char=strcat(char,char(charArray(s1,s2)),']');
        end
       
        function [char] = cellArray2char(cellArray) %transform a (n x p) cell array into an (1 x m) cell array of characters.
            s1=size(cellArray,1);
            s2=size(cellArray,2);
            char='';
            for i=1:s1-1
                for k=1:s2-1
                    char=strcat([char,cellArray{i,k},',']);
                end
                char=strcat([char,cellArray{i,s2},';']);
            end
            for k = 1:s2-1
                    char=strcat(char,cellArray{s1,k},',');
            end
            char=strcat(char,cellArray{s1,s2});
        end
        
        function [char] = char2char(inputChar) %to allow eval(char) to output a char.
            if (ischar(inputChar))
                char=inputChar;
            end    
        end    
            
    end
    
    
    
end

