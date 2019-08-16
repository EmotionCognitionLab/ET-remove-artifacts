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
    % Generate velocity profile
    w1 = hann(config.hann_win*config.resample_multiplier)/sum(hanning(config.hann_win*config.resample_multiplier));     %create hanning window (default is 11 point)
    pupil_smoothed=conv(pupil,w1,'same');                                       %smoothed pupil signal
    vel=[diff(pupil_smoothed); 0]./[diff(timestamp); (timestamp(2) - timestamp(1))];            %velocity profile
    
    S(sub_num).velocity.velocity = vel;
    S(sub_num).velocity.vel_timestamp = timestamp;
    
    % Find blink onset/blink offset index using vel
    neg_threshold = mean(vel)-config.neg_threshold_multiplier*std(vel);
    greater_neg = vel >= neg_threshold;
    less_neg = vel < neg_threshold;
    greater_neg(2:end+1) = greater_neg;
    less_neg(end+1) = less_neg(end);
    blink_index.onset = find(greater_neg&less_neg);
    
    pos_threshold = mean(vel)+config.pos_threshold_multiplier*std(vel);
    greater_pos = vel > pos_threshold;
    less_pos = vel <= pos_threshold;
    greater_pos(2:end+1) = greater_pos;
    less_pos(end+1) = less_pos(end);
    blink_index.offset = find(greater_pos&less_pos);
    
    % Shuffle offsets and onsets by deleting onsets that lie in between an
    % onset and an offset or an offset that came before the onse
    i=1;
    while i<numel(blink_index.offset) && i<numel(blink_index.onset)
        if blink_index.onset(i)<blink_index.offset(i)
            if blink_index.onset(i+1)>blink_index.offset(i)
                i=i+1;
            elseif blink_index.onset(i+1)<=blink_index.offset(i)
                blink_index.onset(i+1) = [];
            end
        elseif blink_index.onset(i)>=blink_index.offset(i)
            blink_index.offset(i) = [];
        end
    end
    
    
    % Delete any leftovers
    if numel(blink_index.onset) > numel(blink_index.offset)
        blink_index.onset(numel(blink_index.offset)+1:end) = [];
    elseif numel(blink_index.onset) < numel(blink_index.offset)
        blink_index.offset(numel(blink_index.onset)+1:end) = [];
    end
    
    % Save to structure
    S(sub_num).blink_onset.velocity = vel(blink_index.onset);
    S(sub_num).blink_onset.vel_timestamp = timestamp(blink_index.onset);
    S(sub_num).blink_onset.sample = pupil(blink_index.onset);
    S(sub_num).blink_onset.smp_timestamp = timestamp(blink_index.onset);
    
    S(sub_num).blink_offset.velocity = vel(blink_index.offset);
    S(sub_num).blink_offset.vel_timestamp = timestamp(blink_index.offset);
    S(sub_num).blink_offset.sample = pupil(blink_index.offset);
    S(sub_num).blink_offset.smp_timestamp = timestamp(blink_index.offset);
    
    % Create blink_array
    blink_array_indices = [];
    for blink_num = 1:numel(blink_index.onset)
        blink_array_indices = [blink_array_indices blink_index.onset(blink_num):blink_index.offset(blink_num)];
    end
    blink_array = zeros(numel(pupil),1);
    blink_array(blink_array_indices) = 1;
    
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