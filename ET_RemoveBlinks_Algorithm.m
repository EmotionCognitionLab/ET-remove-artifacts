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
    config = struct;
elseif nargin == 2
    config = varargin{1};
end

if ~isfield(config,'hann_win') || isempty(config.hann_win)
    config.hann_win = 11;
end
if ~isfield(config,'resample_rate') || isempty(config.resample_rate)
    config.resample_rate = 120;
end
if ~isfield(config,'resample_multiplier') || isempty(config.resample_multiplier)
    if config.resample_multiplier <= 0
        error('Resample Multiplier cannot be less than or equal to 0');
    end
    config.resample_multiplier = 1;
end
if ~isfield(config,'pos_threshold_multiplier') || isempty(config.pos_threshold_multiplier)
    config.pos_threshold_multiplier = 1;
end
if ~isfield(config,'neg_threshold_multiplier') || isempty(config.neg_threshold_multiplier)
    config.neg_threshold_multiplier = 1;
end
if ~isfield(config,'sub_nums') || isempty(config.sub_nums)
    config.sub_nums = 1:numel(S);
    config.iterations = numel(S);
else
    config.iterations = numel(config.sub_nums);
end


for k=1:config.iterations
    sub_num = config.sub_nums(k);
    pupil = S(sub_num).data.sample;
    timestamp = S(sub_num).data.smp_timestamp;
    resample_multiplier = config.resample_multiplier;
    
    %% Resample data and save resampled data to data structure S
    [pupil,timestamp] = resample(pupil,timestamp,config.resample_rate*resample_multiplier,1,1);  %resample data  
    
    S(sub_num).resampled.sample = pupil;                        %need this for plotting in the GUI
    S(sub_num).resampled.smp_timestamp = timestamp;
     
    %% Generate velocity profile
    w1=hann(config.hann_win*resample_multiplier)/sum(hanning(config.hann_win*resample_multiplier));     %create hanning window (default is 11 point)
    pupil_smoothed=conv(pupil,w1,'same');                       %smoothed pupil signal
    vel=diff(pupil_smoothed)./diff(timestamp);                  %velocity profile
    
    S(sub_num).velocity.velocity = vel;
    S(sub_num).velocity.vel_timestamp = timestamp(1:end-1);
    
    %% Find blink onset/blink offset index using vel
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
    
    if numel(blink_index.onset) > numel(blink_index.offset)
        blink_index.onset(numel(blink_index.offset)+1:end) = [];
    elseif numel(blink_index.onset) < numel(blink_index.offset)
        blink_index.offset(numel(blink_index.onset)+1:end) = [];
    end
    
    S(sub_num).blink_onset.velocity = vel(blink_index.onset);
    S(sub_num).blink_onset.vel_timestamp = timestamp(blink_index.onset);
    S(sub_num).blink_onset.sample = pupil(blink_index.onset);
    S(sub_num).blink_onset.smp_timestamp = timestamp(blink_index.onset);
    
    S(sub_num).blink_offset.velocity = vel(blink_index.offset);
    S(sub_num).blink_offset.vel_timestamp = timestamp(blink_index.offset);
    S(sub_num).blink_offset.sample = pupil(blink_index.offset);
    S(sub_num).blink_offset.smp_timestamp = timestamp(blink_index.offset);
    
    %% interpolate - future changes - use "averages" around the timepoints instead of the single value for the timepoints
    for j=1:length(blink_index.onset)
        if timestamp(blink_index.offset(j))-timestamp(blink_index.onset(j)) > 5
            %don't do anything if interpolation region is greater than 5
            %seconds
        else
            t2 = blink_index.onset(j);
            t3 = blink_index.offset(j);
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
