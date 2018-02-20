function CBPStageList
    global oldstage nextstage;
    displen = 36;
    stages = {
        '  Preprocessing:',
        '  * RawDataStage',
        '  * FilterStage',
        '  * WhitenStage',
        '  * InitializeWaveformStage',
        '',
        '  CBP:',
        '  * CBPSetupStage',
        '  * SpikeTimingStage',
        '  * AmplitudeThresholdStage',
        '  * WaveformReestimationStage',
        '',
        '  Post-Analysis:',
        '  * SonificationStage',
        ''
        };

    for n=1:length(stages)
        fprintf(['\n' stages{n}]);
        if isequal(oldstage, stages{n}(5:end))
            fprintf(['\t<' repmat('-',1,displen-4*floor((length(stages{n})/4))-1) '  You just finished here']);
        elseif isequal(nextstage, stages{n}(5:end))
            fprintf(['\t<' repmat('=',1,displen-4*floor((length(stages{n})/4))-1) '  This stage is next']);
        end
    end
    fprintf('\n');
end
