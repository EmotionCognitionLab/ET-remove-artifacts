function [ data ] = ET_ReadFile( filename, config )
%ET_Readfile.m summary:
%   Function for reading ET files in the ET_GUI
%   Input argument is the handles passed from the main GUI script; the
%   handle includes input file name and input file column configurations

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

%% Set-up Format Specs
total_columns = max([msg_col,smp_col,ts_col,type_col]);
formatSpec = '%q %*[^\n]';
for i=2:total_columns
    formatSpec = [formatSpec(1:end-7),'%q %*[^\n]'];
end

fileID = fopen(filename,'r');
columns = textscan(fileID, formatSpec,'Delimiter','\t','TextType','string','HeaderLines',skip_rows);
fclose(fileID);

%% Read in pupil data from SMP rows and message from MSG rows
% create logical arrays
msg_logical_array = strcmp(columns{type_col},type_msg_string);
smp_logical_array = strcmp(columns{type_col},type_smp_string);

% create empty cell arrays to store the data in the handles structure:
data.msg_timestamp = str2double({columns{ts_col}{msg_logical_array}})';
data.message = {columns{msg_col}{msg_logical_array}}';
data.smp_timestamp = str2double({columns{ts_col}{smp_logical_array}})';
data.sample = str2double({columns{smp_col}{smp_logical_array}})';

end

