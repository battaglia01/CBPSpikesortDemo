names = ["inputdlg"];
[filepath,~,~] = fileparts(mfilename('fullpath'))
for n=names
    % first read the old file and generate the new file
    f_old = fopen(n + ".m", 'r');
    old_m = char(fread(f_old))';
    newfix_m = strrep(inputdlg_m, 'Factory', 'Default');

%     % now read the new file and see if it's the same
%     f_new = fopen(filepath + "/" + n + "fix.m", 'r');
%     oldfix_m = char(fread(f_new))';
%     fclose(f_new);

    % now check if they're equal, otherwise overwrite
%     if isequal(oldinputdlgfix_m, newinputdlgfix_m)
%         return;
%     else
        f_new = fopen(filepath + "/" + n + "fix.m", 'w');
        fwrite(f_new, newfix_m);
        fclose(f_new);
%     end
end

fclose(f_old);
% fclose(f_new);