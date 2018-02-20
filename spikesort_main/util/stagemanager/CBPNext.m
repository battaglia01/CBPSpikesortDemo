function CBPNext
    global stages currstageind;
    nextstage = stages{currstageind}{2};
    nextstage();
end