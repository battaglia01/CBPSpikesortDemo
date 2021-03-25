function snippets = GetSnippetsFromCellRanges(idx_list, signal)
    snippets = cell(length(idx_list), 1);
    for zone_num = 1 : length(idx_list)
        snippets{zone_num} = signal(idx_list{zone_num}, :);
    end
end