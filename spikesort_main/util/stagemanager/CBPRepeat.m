function CBPNext
    global stages currstageind;
    oldstage = stages{currstageind}{1};
    oldstage();
end