classdef StageObject < handle
  properties
    % set internally by RegisterStage
    mainfun                     % main function handle
    plotfun                     % plot function handle
    nextfun                     % next stage's main function handle
    stagenum                    % stage number
    
    % basic properties
    name                        % stage's name
    next                        % next stage's name
    category                    % stage category (i.e. "Preprocessing")
    description                 % stage description
    paramname                   % params subobject name that this stage corresponds to
    
    % optional parameters
    replotoncellchange = false  % if this is set, replot whenever cell plot changes
    showreview = false          % this is set to true for the last CBP stage before post-analysis
    
    % temporary flags that change
    needsreplot = false         % this is set to true when the cell plot changes
  end
end