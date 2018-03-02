% This is an example script using ET_ReadFile.m to read data file outputs
% from SMI (SensoMotoric Instrument) eye-trackers to a Matlab data
% structure. 
%
% This script demosntrates how to create a script to read data from raw
% eye-tracking file to a Matlab data structure that is formatted to work
% with ET-remove-artifact's GUI.
%
% Author: Ringo Huang (ringohua@usc.edu)

%% Set-up the formatting configurations for my raw data file
config.type_msg_string = 'MSG';
config.type_smp_string = 'SMP';
config.type_col = 2;
config.msg_col = 4;
config.smp_col = 8;
config.ts_col = 1;

files = dir('Example*.txt'); %Get file info for all raw data files in this directory

%% Read file data (ET_ReadFile) to data structure S
for S_num = 1:numel(files)
    disp(['Reading file ' num2str(S_num)]);
    S(S_num).data = ET_ReadFile(files(S_num).name,config);
    S(S_num).data.smp_timestamp = S(S_num).data.smp_timestamp/10^6;     % Convert data to seconds
    S(S_num).SubjectNumber = str2double(files(S_num).name(16:18));      % save sub num into the sub_num field
    fclose all;
end

%% Save the data structure
save('Example_Data_Input.mat','S');