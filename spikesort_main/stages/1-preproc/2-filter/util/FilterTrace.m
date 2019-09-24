% Filter trace
function [data,coeffs] = FilterTrace(raw_data, filtering, rate)
    if (isempty(filtering.freq))
      data = raw_data;
      return;
    end
    % Preprocessing parameters (see Harris et al 2000)
    Wn = filtering.freq  / rate;

    if ((length(Wn)==1) || (Wn(2) >= 1))
        switch(filtering.type)
            case 'butter'
                [fb, fa] = butter(filtering.order, Wn(1), 'high');
                fprintf('Highpass butter filtering with cutoff %f Hz\n', ...
                    filtering.freq(1));
            case 'fir1'
                fb = fir1(filtering.order, Wn(1), 'high');
                fa = 1;
                fprintf('Highpass fir1 filtering with cutoff %f Hz\n', ...
                    filtering.freq(1));
        end
    else
        switch(filtering.type)
            case 'butter'
                [fb, fa] = butter(filtering.order, Wn, 'bandpass');
                fprintf('Bandpass butter filtering with cutoff %s Hz\n', ...
                    mat2str(filtering.freq));
            case 'fir1'
                fb = fir1(filtering.order, Wn, 'bandpass');
                fa = 1;
                fprintf('Bandpass fir1 filtering with cutoff %s Hz\n', ...
                    mat2str(filtering.freq));
        end
    end
    coeffs = {fb fa};
    data = zeros(size(raw_data));
    parfor chan = 1 : size(raw_data, 1)
        data(chan, :) = filter(fb, fa, raw_data(chan, :));
    end
end
