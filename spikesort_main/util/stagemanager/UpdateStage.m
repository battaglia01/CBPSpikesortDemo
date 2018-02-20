function UpdateStage(newstage)
    global stages currstageind;
    
    ind = 0;
    found = false;
    for n=1:length(stages)
        if isequal(stages{n}{1}, newstage)
            ind = n;
            found = true;
        end
        if found & ~isempty(stages{n}{3})
            stages{n}{3}(false);    %clear display
        end
    end
    pause(.001); %needed to make sure things clear
    currstageind = ind;
end