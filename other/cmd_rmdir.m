function [st, msg] = cmd_rmdir(fullpath)       
%   cmd_rmdir removes a directory and its contents 
%   
%   Removes all directories and files in the specified directory in
%   addition to the directory itself.  Used to remove a directory tree.
           
    narginchk(1, 1);
    
    dos_cmd = sprintf('rmdir /S /Q "%s"', fullpath);
    
    [st, msg] = system(dos_cmd);
end