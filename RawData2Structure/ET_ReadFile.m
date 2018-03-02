function [ data ] = ET_ReadFile( filename,  config )
%ET_Readfile.m summary:
%   Function for reading ET files in the ET_GUI
%   Input argument is the handles passed from the main GUI script; the
%   handle includes input file name and input file column configurations

%   BUG TO FIX: for now, the timestamp column must come before the sample and
%   message columns
% 
% config.type_msg_string = 'MSG';
% config.type_smp_string = 'SMP';
% config.type_col = 2;
% config.msg_col = 4;
% config.smp_col = 8;
% config.ts_col = 1;

%% Retrieve file configuration
%Required fields
if ~isfield(config,'type_msg_string') || ~isfield(config,'type_smp_string') || ~isfield(config,'type_col') || ~isfield(config,'msg_col') || ~isfield(config,'smp_col') || ~isfield(config,'ts_col')
    error('Missing one or more required fields in the config structure.')
else
    if ~ischar(config.type_msg_string) || ~ischar(config.type_smp_string)
        error('The fields type_msg_string and type_smp_string must be strings.')
    end
    if ~isa(config.type_col,'double') || ~isa(config.msg_col,'double') || ~isa(config.smp_col,'double') || ~isa(config.ts_col,'double')
        error('The "column" fields (e.g., type_col) must be integers')
    end
    type_msg_string = config.type_msg_string;
    type_smp_string = config.type_smp_string;
    type_col = config.type_col;
    msg_col = config.msg_col;
    smp_col = config.smp_col;
    ts_col = config.ts_col;
end

%Optional fields - if field is missing in the config struct, use default
if ~isfield(config,'duration_col')
    duration_col = [];
else
    duration_col = config.duration_col;
end
if ~isfield(config,'skip_rows')
    skip_rows = 0;
else
    skip_rows = config.skip_rows;
end

%Temporary error message for a bug (need to fix)
if ts_col > msg_col || ts_col > smp_col
    error('In the input file, the timestamp column must come before the message column and the sample column. I need to fix this bug');
end

%% Initialize fileID1 (for linecheck) and fileID2 (for saving the data)
fileID1 = fopen(filename);
fileID2 = fopen(filename);

%% Skip the first user-given number of rows (e.g., if there are file info) for both fileID's
textscan(fileID1, '%s %*[^\n]', skip_rows);
textscan(fileID2, '%s %*[^\n]', skip_rows);

%% Set the line formats
msg_format = [repmat('%s\t',1,msg_col-1) '%s%*[^\n]'];
smp_format = [repmat('%s\t',1,smp_col-1) '%s%*[^\n]'];
linecheck_format = [repmat('%*s\t',1,type_col-1) '%s%*[^\n]'];

%% Read in pupil data from SMP rows and message from MSG rows
count = 0;
msg_count = 0;
smp_count = 0;

%create empty arrays as fields in the structure
data.msg_timestamp = [];
data.message = {};
data.smp_timestamp = [];
data.sample = [];

%read data from data file to data structure
while (~feof(fileID1))
    count = count+1;
    linecheck = textscan(fileID1, linecheck_format, 1, 'delimiter', '\t');
    
    if strcmp(linecheck{1}, type_msg_string)                                %use this data format if the row is a MSG
        msg_count = msg_count + 1;
        line = textscan(fileID2, msg_format, 1, 'delimiter', '\t');
        data.msg_timestamp(msg_count,1) = str2double(line{ts_col});         %save timestamps to array
        data.message{msg_count,1} = line{msg_col}{1};                       %save message to cells
    elseif strcmp(linecheck{1}, type_smp_string)                            %use this data format if the row is a SMP
        smp_count = smp_count + 1;
        line = textscan(fileID2, smp_format, 1, 'delimiter', '\t');
        data.smp_timestamp(smp_count,1) = str2double(line{ts_col});
        data.sample(smp_count,1) = str2double(line{smp_col});
        if ~isnan(duration_col)                                             %if user entered a value for the duration_col field
            data.smp_duration(smp_count,1) = str2double(line{duration_col});
        end
    else                                                                    %skip row
        textscan(fileID2, '%s %*[^\n]',1);
    end
end