function S = ET_RemoveBlinks_Algorithm(S, varargin)
% Algorithm to automatically removes blinks in a pupillary signal.
%
% Based on the process described by Sebastiaan Mathot:
% www.researchgate.net/publication/236268543_A_simple_way_to_reconstruct_pupil_size_during_eye_blinks
%
% Input data structure S requires field "data" with sub-fields "sample" and
% "smp_timestamp". Outputs the same data structure S with new field
% "reconstructed".
%
% Steps:
%   1. Resample data
%   2. Generate velocity profile - first smooth the data using a hanning
%   window
%   3. Detect blink onsets/offsets by identifying intersections between
%   velocity profile and negative/positive threshold
%   4. Interpolate over blink onset/offset pairs
%
% Note: If the blink onset/offset pair is greater than 5 seconds, this
% program does not interpolate over that region. Could be that the signal
% is missing data over that period, a series of successive blinks, or some
% other weird behavior of the signal. At any rate, I feel like best
% practice is to not interpolate over this region. Instead, you can use the
% manual editing tool to replace longer periods of "messy" signal with
% NaNs.
%
% This function is called within ET_ReconstructPlots_GUI.m whenever user
% presses the pushbutton "Filter Blinks". This function can also be called
% as a standalone function.
%
% Author: Ringo Huang (ringohua@usc.edu)

%% Unpack arguments
narginchk(1,2);
if nargin == 1
    config = struct;        % If no config is specified
elseif nargin == 2
    config = varargin{1};   % If config is specified
end

% General Preprocessing:
config = check_sub_field_and_assign_default(config, 'resample_rate');
config = check_sub_field_and_assign_default(config, 'resample_multiplier');

% Detect Blinks:
config = check_sub_field_and_assign_default(config, 'detect_blinks');
config = check_sub_field_and_assign_default(config, 'hann_window');
config = check_sub_field_and_assign_default(config, 'filter_order');
config = check_sub_field_and_assign_default(config, 'peak_boundary_threshold');
config = check_sub_field_and_assign_default(config, 'trough_boundary_threshold');
config = check_sub_field_and_assign_default(config, 'passband_freq');
config = check_sub_field_and_assign_default(config, 'stopband_freq');
config = check_sub_field_and_assign_default(config, 'peak_threshold_factor');
config = check_sub_field_and_assign_default(config, 'trough_threshold_factor');
config = check_sub_field_and_assign_default(config, 'pos_threshold_multiplier');
config = check_sub_field_and_assign_default(config, 'neg_threshold_multiplier');

% Detect Invalid Samples:
config = check_sub_field_and_assign_default(config, 'detect_invalid_samples');
config = check_sub_field_and_assign_default(config, 'front_padding');
config = check_sub_field_and_assign_default(config, 'rear_padding');
config = check_sub_field_and_assign_default(config, 'merge_invalids_gap');

% Interpolation Options:
config = check_sub_field_and_assign_default(config, 'merge_artifacts_gap');
config = check_sub_field_and_assign_default(config, 'max_artifact_duration');
config = check_sub_field_and_assign_default(config, 'max_artifact_treatment');

% Other:
if ~isfield(config,'sub_nums') || isempty(config.sub_nums)
    config.sub_nums = 1:numel(S);                   % run on all S_nums
    config.iterations = numel(S);
else
    config.iterations = numel(config.sub_nums);     % run only user-specified sub_nums
end


for k=1:config.iterations
    sub_num = config.sub_nums(k);
    
    %% Resample data sub_fields
    if isfield(S(sub_num),'data')
        if isfield(S(sub_num).data,'smp_timestamp')
            if isfield(S(sub_num).data,'sample')
                [pupil,timestamp] = resample(S(sub_num).data.sample, S(sub_num).data.smp_timestamp,config.resample_rate*config.resample_multiplier,1,1);    % resample sample
                S(sub_num).resampled.sample = pupil;
                S(sub_num).resampled.smp_timestamp = timestamp;
            else
                error('Could not find "sample" sub-field.');
            end
            if isfield(S(sub_num).data,'valid')
                if islogical(S(sub_num).data.valid)
                    S(sub_num).data.valid = double(S(sub_num).data.valid);      % convert logical array to double for resample fn to work
                end
                valid = round(resample(S(sub_num).data.valid, S(sub_num).data.smp_timestamp,config.resample_rate*config.resample_multiplier,1,1));                 % resample valid; also, round binarizes the resampled "logical" array
                
                S(sub_num).resampled.valid = valid;
            else
                % Not critical if "valid" is missing
            end
        else
            error('Could not find "smp_timestamp" field.');
        end
    else
        error('Could not find "data" sub-field.');
    end
    
    %% Detect Blinks
    % Generate velocity profile using differentiator FIR filter
    
    
    d = designfilt('differentiatorfir','FilterOrder',config.filter_order, ...
        'PassbandFrequency',config.passband_freq,'StopbandFrequency',config.stopband_freq, ...
        'SampleRate',config.resample_rate);
    
    dt = timestamp(2)-timestamp(1);
    
    delay = mean(grpdelay(d));
    pupil_pad = [repmat(pupil(1),delay,1); pupil; repmat(pupil(end),delay,1)];      % add 2*delay number of samples of the first pupil_smoothed value to beginning
    
    vel = filter(d,pupil_pad)/dt;
        
    vel(1:2*delay) = [];
    
    S(sub_num).velocity.velocity = vel;
    S(sub_num).velocity.vel_timestamp = timestamp;
    
    % Detect peak, troughs, and their boundaries
    [peak,peak_loc] = findpeaks(vel);
    [trough,trough_loc] = findpeaks(-vel);
    trough = - trough;
    
    % Find outlier peaks/troughs - these are the "artifact" peaks/troughs
    peak_outlier_la = isoutlier(peak,'ThresholdFactor',config.peak_threshold_factor) & peak > 0;
    trough_outlier_la = isoutlier(trough,'ThresholdFactor',config.trough_threshold_factor) & trough < 0;
    
    peak_outlier = peak(peak_outlier_la);
    peak_loc_outlier = peak_loc(peak_outlier_la);
    trough_outlier = trough(trough_outlier_la);
    trough_loc_outlier = trough_loc(trough_outlier_la);
    
    % Find boundaries of "artifact" peaks/troughs (sample with sign change or trough, whichever comes first)
    neg_locs = find(vel < config.peak_boundary_threshold);
    pos_locs = find(vel > config.trough_boundary_threshold);
    
    peak_start_loc = [];
    peak_end_loc = [];
    for i = 1:numel(peak_loc_outlier)
        neg_locs_index = find(neg_locs > peak_loc_outlier(i),1,'first');
        if isempty(neg_locs_index)
            continue
        end
        if neg_locs_index > 1
            peak_start_loc(i) = neg_locs(neg_locs_index-1);
        else
            peak_start_loc(i) = 1;
        end
        peak_end_loc(i) = neg_locs(neg_locs_index);
        
        % Non-outlier troughs that come before or after peak_loc_outlier(i)
        start_trough_loc = trough_loc(find(trough_loc < peak_loc_outlier(i),1,'last'));
        end_trough_loc = trough_loc(find(trough_loc > peak_loc_outlier(i),1,'first'));
        
        % Check if a trough comes before; replace peak_start_loc with trough if
        % so
        if peak_start_loc(i) < start_trough_loc
            peak_start_loc(i) = start_trough_loc;
        end
        if peak_end_loc(i) > end_trough_loc
            peak_end_loc(i) = end_trough_loc;
        end
        
    end
    
    trough_start_loc = [];
    trough_end_loc = [];
    for i = 1:numel(trough_loc_outlier)
        pos_locs_index = find(pos_locs > trough_loc_outlier(i),1,'first');
        if isempty(pos_locs_index)
            continue
        end
        if pos_locs_index > 1
            trough_start_loc(i) = pos_locs(pos_locs_index-1);
        else
            trough_start_loc(i) = 1;
        end
        trough_end_loc(i) = pos_locs(pos_locs_index);
        
        % Non-outlier peaks that come before or after peak_loc_outlier(i)
        start_peak_loc = peak_loc(find(peak_loc < trough_loc_outlier(i),1,'last'));
        end_peak_loc = peak_loc(find(peak_loc > trough_loc_outlier(i),1,'first'));
        
        % Check if a trough comes before; replace peak_start_loc with trough if
        % so
        if trough_start_loc(i) < start_peak_loc
            trough_start_loc(i) = start_peak_loc;
        end
        if trough_end_loc(i) > end_peak_loc
            trough_end_loc(i) = end_peak_loc;
        end
        
    end
    
    % Merge boundaries
    start_boundary = [peak_start_loc trough_start_loc];
    end_boundary = [peak_end_loc trough_end_loc];
    blink_array = zeros(numel(pupil),1);
    for i = 1:numel(start_boundary)
        blink_array(start_boundary(i):end_boundary(i)) = 1;
    end
    
    blink_la_diff = diff([0; blink_array]);
    
    blink_index.onset = find(blink_la_diff == 1);
    blink_index.offset  = find(blink_la_diff == -1)-1;
    
    
    % Save to structure
    S(sub_num).blink_onset.velocity = vel(blink_index.onset);
    S(sub_num).blink_onset.vel_timestamp = timestamp(blink_index.onset);
    S(sub_num).blink_onset.sample = pupil(blink_index.onset);
    S(sub_num).blink_onset.smp_timestamp = timestamp(blink_index.onset);
    
    S(sub_num).blink_offset.velocity = vel(blink_index.offset);
    S(sub_num).blink_offset.vel_timestamp = timestamp(blink_index.offset);
    S(sub_num).blink_offset.sample = pupil(blink_index.offset);
    S(sub_num).blink_offset.smp_timestamp = timestamp(blink_index.offset);
    
    
    %% Detect Invalids
    invalid_array = zeros(numel(pupil),1);      % initiate invalid_array as an array of zeros of same length as pupil array; will replace if "valid" is detected as part of the data structure
    
    if isfield(S(sub_num).data, 'valid') && ~isempty(S(sub_num).data.valid)
        
        invalid_array = ~valid;
        invalid_diff = diff([0; invalid_array; 0]);     % pad front and rear with a zero
        invalid_index.onset = find(invalid_diff == 1);
        invalid_index.offset = find(invalid_diff == -1) - 1;
        
        % Add padding to the onset/offsets
        front_padding_indices = round(config.front_padding/(timestamp(2)-timestamp(1)));
        rear_padding_indices = round(config.rear_padding/(timestamp(2)-timestamp(1)));
        invalid_index.onset = invalid_index.onset - front_padding_indices;
        invalid_index.offset = invalid_index.offset + rear_padding_indices;
        
        % Create invalid array (event if there's overlap of invalid regions
        % - due to padding - the way matlab assigns values to array gets
        % around it).
        invalid_array_indices = [];
        for invalid_num = 1:numel(invalid_index.onset)
            if invalid_index.onset(invalid_num) < 1                 % replace index with 1 if front-padding brought it to a non-positive number
                invalid_index.onset(invalid_num) = 1;
            end
            if invalid_index.offset(invalid_num) > numel(pupil)     % replace index with numel(pupil) if rear-padding brought it to greater than number of pupil samples
                invalid_index.offset(invalid_num) = numel(pupil);
            end
            invalid_array_indices = [invalid_array_indices invalid_index.onset(invalid_num):invalid_index.offset(invalid_num)];
        end
        invalid_array = zeros(numel(pupil),1);
        invalid_array(invalid_array_indices) = 1;
        
        S(sub_num).invalid_onset.velocity = vel(invalid_index.onset);
        S(sub_num).invalid_onset.vel_timestamp = timestamp(invalid_index.onset);
        S(sub_num).invalid_onset.sample = pupil(invalid_index.onset);
        S(sub_num).invalid_onset.smp_timestamp = timestamp(invalid_index.onset);
        
        S(sub_num).invalid_offset.velocity = vel(invalid_index.offset);
        S(sub_num).invalid_offset.vel_timestamp = timestamp(invalid_index.offset);
        S(sub_num).invalid_offset.sample = pupil(invalid_index.offset);
        S(sub_num).invalid_offset.smp_timestamp = timestamp(invalid_index.offset);
    end
    
    %% Merge blink_index and invalid_index to create artifact_index
    artifact_array = invalid_array*config.detect_invalid_samples | blink_array*config.detect_blinks;      % if the tag for detect blink or detect invalid is 0, then the array contributes no weight to artifact_array
    artifact_diff = diff([0; artifact_array; 0]);
    artifact_index.onset = find(artifact_diff == 1);
    artifact_index.offset = find(artifact_diff == -1) - 1;
    
    S(sub_num).artifact_onset.velocity = vel(artifact_index.onset);
    S(sub_num).artifact_onset.vel_timestamp = timestamp(artifact_index.onset);
    S(sub_num).artifact_onset.sample = pupil(artifact_index.onset);
    S(sub_num).artifact_onset.smp_timestamp = timestamp(artifact_index.onset);
    
    S(sub_num).artifact_offset.velocity = vel(artifact_index.offset);
    S(sub_num).artifact_offset.vel_timestamp = timestamp(artifact_index.offset);
    S(sub_num).artifact_offset.sample = pupil(artifact_index.offset);
    S(sub_num).artifact_offset.smp_timestamp = timestamp(artifact_index.offset);
    %% interpolate - future changes - use "averages" around the timepoints instead of the single value for the timepoints
    for j=1:length(artifact_index.onset)
        
        
        if timestamp(artifact_index.offset(j))-timestamp(artifact_index.onset(j)) > 60
            %don't do anything if interpolation region is greater than 5
            %seconds
        else
            t2 = artifact_index.onset(j);
            t3 = artifact_index.offset(j);
            t1 = t2-t3+t2;
            t4 = t3-t2+t3;
            if t1 <= 0
                t1 =1;
            end
            if t4 > numel(pupil)
                t4 = numel(pupil);
            end
            if t3 < t2
                continue
            end
            if t1 == t2 || t2 == t3 || t3 == t4
                continue
            end
            x = [t1,t2,t3,t4];
            v = [pupil(t1),pupil(t2),pupil(t3),pupil(t4)];
            xq = t2:t3;
            vq = interp1(x,v,xq,'linear');
            pupil(t2:t3) = vq;
        end
    end
    
    %% Update Data structure S to be outputted
    S(sub_num).reconstructed.sample = pupil;
    S(sub_num).reconstructed.smp_timestamp = timestamp;
end
end

%% Nested functions
function config = check_sub_field_and_assign_default(config, sub_field_name)
% Checks that sub_field of config exists and is populated; If it's
% invalid, assign default value
%
% Note: define default values for each sub_field parameter here

if ~isfield(config,sub_field_name) || isempty(config.(sub_field_name))
    switch sub_field_name
        case 'resample_rate'
            default_value = 120;
        case 'resample_multiplier'
            if config.resample_multiplier <= 0
                error('Resample Multiplier cannot be less than or equal to 0');
            end
            default_value = 1;
        case 'detect_blinks'
            default_value = 1;      % enable detect blinks by default
        case 'hann_window'
            default_value = 11;
        case 'filter_order'
            default_value = 20;
        case 'peak_boundary_threshold'
            default_value = 0;
        case 'trough_boundary_threshold'
            default_value = 0;
        case 'passband_freq'        % change to be more robust
            default_value = 10;            
        case 'stopband_freq'        % change to be more robust
            default_value = 12;
        case 'peak_threshold_factor'        % change to be more robust
            default_value = 1;
        case 'trough_threshold_factor'        % change to be more robust
            default_value = 1;             
        case 'pos_threshold_multiplier'
            default_value = 1;
        case 'neg_threshold_multiplier'
            default_value = 1;
        case 'detect_invalid_samples'
            default_value = 0;      % disable detect invalid samples by default
        case 'front_padding'
            default_value = 0;      % default is 0 s
        case 'rear_padding'
            default_value = 0;      % default is 0 s
        case 'merge_invalids_gap'
            default_value = 0;      % default is 0 s
        case 'merge_artifacts_gap'
            default_value = 0;
        case 'max_artifact_duration'
            default_value = 0;
        case 'max_artifact_treatment'
            default_value = 'ignore';
    end
    config.(sub_field_name) = default_value;
end
end