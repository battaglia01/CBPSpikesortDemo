% quick helper function that auto-replaces " " in tag names with "_"
% moved to its own function in case we want to change everything quick
function out = formattagname(in)
    out = "tag_" + regexprep(in,"[^A-Za-z0-9]","_");
end