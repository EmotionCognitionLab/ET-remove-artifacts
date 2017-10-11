function S = ET_ReconstructPlots_GUI(varargin)
%Reconstructs pupillary signal using two approaches:
%   1) Applies an automatic blink detection and reconstruction algorithm on
%   the original pupil data. Users can tinker with the algorithm parameters
%   and view the results of the reconstruction
%   2) Allows users to manually edit the reconstructed plot to fix
%   artifacts that were undetected by the automatic reconstruction
%   algorithm
%
%Pupil data needs to first be stored in a data structure, variable S
%   Minimal requirements of populated fields for this program to work:
%   1) S.data.sample contains a double array of pupil data
%   2) S.data.smp_timestamp contains the double array of timestamps
%
%There are three ways to call the function:
%   1) ET_ReconstructPlots_GUI
%       Select the file that contains your data structure S from within the
%       GUI. You can save your changes in the same file or save your
%       changes as a new file.
%   2) ET_ReconstructPlots_GUI(S);
%       Loads the data structure S as an input argument. You MUST save
%       changes into a new file using the Save As button.
%   3) S = ET_ReconstructPlots_GUI(S);
%       Loads the data structure S as an input argument and saves changes
%       to output argument S. The output data structure S is a temporary
%       variable in your current Matlab workspace. To permanently save
%       your changes after exiting the GUI, you must save the variable S in
%       your Matlab workspace - e.g., save('ExampleFile','S')
%
%Code Changes:
% 10/8/2017 - controlled resizing behavior and got rid of scrollbars
% 10/10/2017 - added hotkeys to the plot editor
%
%Author: Ringo Huang (ringohua@usc.edu)

%% Check argument
narginchk(0,1);
if nargin == 1
    if ~isstruct(varargin{1}), error('Input argument must be a data structure'); end
end

%% Initialize figure
figure_handle = figure('Name','ET Reconstruct Plots',...
    'Resize','On',...
    'CloseRequestFcn',@closefigure_call);
h = guihandles(figure_handle);

[h.x_dim_max,h.y_dim_max]=maximize_figure(figure_handle);   %"true" figure maximize

%% Load in data structure S if it is passed as an input argument
if nargin == 1
    S = varargin{1};
    h.S = S;
end

%% Set-up axes
h.ax(1) = axes('Parent',figure_handle,...
    'Units','Pixels');
h.ax(1).XLabel.String = 'Time (Seconds)';
h.ax(1).YLabel.String = 'Unknown Units';
h.ax(1).Title.String = 'Velocity Plot';
h.ax(1).XAxis.FontSize = 9;
h.ax(1).YAxis.FontSize = 9;
h.ax(1).XLabel.FontSize = 9;
h.ax(1).YLabel.FontSize = 9;
h.ax(1).Title.FontSize = 12;

h.ax(2) = axes('Parent',figure_handle,...
    'Units','Pixels');
h.ax(2).XLabel.String = 'Time (Seconds)';
h.ax(2).YLabel.String = 'Unknown Units';
h.ax(2).Title.String = 'Pupil Plot';
h.ax(2).XAxis.FontSize = 9;
h.ax(2).YAxis.FontSize = 9;
h.ax(2).XLabel.FontSize = 9;
h.ax(2).YLabel.FontSize = 9;
h.ax(2).Title.FontSize = 12;

h.pl(1) = line('Color',[0 0.8 1],...
    'LineStyle','-',...
    'Parent',h.ax(1),...
    'Visible','Off');
h.pl(2) = line('Color',[0 0.5 0],...
    'LineStyle','none',...
    'Marker','x',...
    'Parent',h.ax(1),...
    'Visible','Off');
h.pl(3) = line('Color', [0.8 0.3 0],...
    'LineStyle','none',...
    'Marker','x',...
    'Parent',h.ax(1),...
    'Visible','Off');

h.pl(4) = line('Color','green',...
    'LineStyle','-',...
    'Parent',h.ax(2),...
    'Visible','Off');
h.pl(5) = line('Color','blue',...
    'LineStyle','-',...
    'Parent',h.ax(2),...
    'Visible','Off');
h.pl(6) = line('Color',[0 0.5 0],...
    'LineStyle','none',...
    'Marker','x',...
    'Parent',h.ax(2),...
    'Visible','Off');
h.pl(7) = line('Color', [0.8 0.3 0],...
    'LineStyle','none',...
    'Marker','x',...
    'Parent',h.ax(2),...
    'Visible','Off');

%% Set-up Load Data Panel
h.pn1 = uipanel('Parent',figure_handle,...
    'Units','Pixels',...
    'Title','Load Data',...
    'FontSize',10);
h.pn(1).pb(1) = uicontrol('Style','PushButton',...
    'Parent',h.pn1,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',10,...
    'Position',[20 20 80 30],...
    'String','Select Data',...
    'Tooltip','Select the variable that stores your data structure',...
    'Callback',@selectdata_call);
h.pn(1).ed(2) = uicontrol('Style','Edit',...
    'BackgroundColor',[1 1 1],...
    'Parent',h.pn1,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',10,...
    'Enable','off',...
    'Position',[105 20 220 30]);
h.pn(1).tx(2) = uicontrol('Style','Text',...
    'Parent',h.pn1,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',10,...
    'Position',[350 16 40 30],...
    'String','Index');
h.pn(1).ed(1) = uicontrol('Style','Edit',...
    'Parent',h.pn1,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',10,...
    'Position',[390 20 40 30]);

%% Set-up Display Plots Panel
h.pn2 = uipanel('Parent',figure_handle,...
    'Units','Pixels',...
    'Title','Display Plots',...
    'FontSize',10);
%Left Side
h.pn(2).tx(1) = uicontrol('Style','Text',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontAngle','Italic',...
    'FontSize',9,...
    'Position',[20 105 80 30],...
    'String','Velocity Plot');
h.pn(2).rb(1) = uicontrol('Style','RadioButton',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'Position',[20 95 15 15],...
    'Tag','Velocity');
h.pn(2).rb(2) = uicontrol('Style','RadioButton',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'Position',[20 70 15 15],...
    'Tag','Velocity_Blink_Onset');
h.pn(2).rb(3) = uicontrol('Style','RadioButton',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'Position',[20 45 15 15],...
    'Tag','Velocity_Blink_Offset');
h.pn(2).tx(2) = uicontrol('Style','Text',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',8,...
    'Position',[45 95 150 15],...
    'String','Velocity (Cyan)');
h.pn(2).tx(3) = uicontrol('Style','Text',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',8,...
    'Position',[45 70 150 15],...
    'String','Blink Onset (Dark Green X)');
h.pn(2).tx(4) = uicontrol('Style','Text',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',8,...
    'Position',[45 45 150 15],...
    'String','Blink Offset (Dark Red X)');

%Right Side
h.pn(2).tx(5) = uicontrol('Style','Text',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontAngle','Italic',...
    'FontSize',9,...
    'Position',[245 105 80 30],...
    'String','Pupil Plot');
h.pn(2).rb(4) = uicontrol('Style','RadioButton',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'Position',[245 95 15 15],...
    'Tag','Original');
h.pn(2).rb(5) = uicontrol('Style','RadioButton',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'Position',[245 70 15 15],...
    'Tag','Reconstructed');
h.pn(2).rb(6) = uicontrol('Style','RadioButton',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'Position',[245 45 15 15],...
    'Tag','Pupil_Blink_Onset');
h.pn(2).rb(7) = uicontrol('Style','RadioButton',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'Position',[245 20 15 15],...
    'Tag','Pupil_Blink_Offset');
h.pn(2).tx(6) = uicontrol('Style','Text',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',8,...
    'Position',[270 95 150 15],...
    'String','Original (Bright Green)');
h.pn(2).tx(7) = uicontrol('Style','Text',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',8,...
    'Position',[270 70 150 15],...
    'String','Reconstructed (Blue)');
h.pn(2).tx(8) = uicontrol('Style','Text',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',8,...
    'Position',[270 45 150 15],...
    'String','Blink Onset (Dark Green X)');
h.pn(2).tx(9) = uicontrol('Style','Text',...
    'Parent',h.pn2,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',8,...
    'Position',[270 20 150 15],...
    'String','Blink Offset (Dark Red X)');

%% Set-up Filter Parameters
%Write tooltip strings
tooltip_hann_win = sprintf(...
    ['Larger values for the hanning window increases smoothing for the\n',...
    'velocity plot. Zoom in on a section of your velocity plot. If you\n',...
    'see small noisy fluctuations, increase the hanning window value.']);
tooltip_resample = sprintf(...
    ['I recommend setting this to the sampling rate (in Hz) of your\n',...
    'eye-trackinig device.']);
tooltip_precision = sprintf(...
    ['I recommend leaving this at 0 if you plan on manually editing\n',...
    'your data. The precision parameter tells the algorithm to collapse\n',...
    'two blink events that occurs within the defined precision (in seconds).']);
tooltip_pos_threshold = sprintf(...
    ['Smaller values delays the blink offset and extends the tail end\n',...
    'of the interpolation region.']);
tooltip_neg_threshold = sprintf(...
    ['Smaller values advances the blink onset and extends the starting\n',...
    'point of the interpolation region.']);

%Velocity Pos/Neg Threshold, Hanning window, precision, resample rate
h.pn3 = uipanel('Parent',figure_handle,...
    'Units','Pixels',...
    'Title','Filter Parameters',...
    'FontSize',10);
h.pn(3).tx(1) = uicontrol('Style','Text',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',9,...
    'Position',[20 115 120 15],...
    'String','Hanning Window',...
    'Tooltip',tooltip_hann_win);
h.pn(3).tx(2) = uicontrol('Style','Text',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',9,...
    'Position',[20 90 120 15],...
    'String','Resampling Rate',...
    'Tooltip',tooltip_resample);
h.pn(3).tx(3) = uicontrol('Style','Text',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',9,...
    'Position',[20 65 120 15],...
    'String','Precision',...
    'Tooltip',tooltip_precision);
h.pn(3).tx(4) = uicontrol('Style','Text',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',9,...
    'Position',[20 40 120 15],...
    'String','Velocity Threshold (+)',...
    'Tooltip',tooltip_pos_threshold);
h.pn(3).tx(5) = uicontrol('Style','Text',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Left',...
    'FontSize',9,...
    'Position',[20 15 120 15],...
    'String','Velocity Threshold (-)',...
    'Tooltip',tooltip_neg_threshold);
h.pn(3).ed(1) = uicontrol('Style','Edit',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',8,...
    'Position',[145 112 35 20],...
    'Tooltip',tooltip_hann_win);
h.pn(3).ed(2) = uicontrol('Style','Edit',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',8,...
    'Position',[145 87 35 20],...
    'Tooltip',tooltip_resample);
h.pn(3).ed(3) = uicontrol('Style','Edit',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',8,...
    'Position',[145 62 35 20],...
    'Tooltip',tooltip_precision);
h.pn(3).ed(4) = uicontrol('Style','Edit',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',8,...
    'Position',[145 37 35 20],...
    'Tooltip',tooltip_pos_threshold);
h.pn(3).ed(5) = uicontrol('Style','Edit',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',8,...
    'Position',[145 12 35 20],...
    'Tooltip',tooltip_neg_threshold);
h.pn(3).pb(1) = uicontrol('Style','PushButton',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',10,...
    'Position',[240 60 80 30],...
    'String','Filter Plot');
h.pn(3).pb(2) = uicontrol('Style','PushButton',...
    'Parent',h.pn3,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',10,...
    'Position',[340 60 80 30],...
    'String','Undo');

%% Set-up PushButtons Panel
h.pn4 = uipanel('Parent',figure_handle,...
    'Units','Pixels',...
    'FontSize',10);
h.pn(4).pb(1) = uicontrol('Style','PushButton',...
    'Parent',h.pn4,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',10,...
    'Position',[60 80 330 30],...
    'String','Manually Edit Plot');
h.pn(4).pb(2) = uicontrol('Style','PushButton',...
    'Parent',h.pn4,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',10,...
    'Position',[120 45 80 30],...
    'String','Back');
h.pn(4).pb(3) = uicontrol('Style','PushButton',...
    'Parent',h.pn4,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',10,...
    'Position',[250 45 80 30],...
    'String','Next');
h.pn(4).pb(4) = uicontrol('Style','PushButton',...
    'Parent',h.pn4,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',10,...
    'Position',[120 10 80 30],...
    'String','Save As');
h.pn(4).pb(5) = uicontrol('Style','PushButton',...
    'Parent',h.pn4,...
    'Units','Pixels',...
    'HorizontalAlignment','Center',...
    'FontSize',10,...
    'Position',[250 10 80 30],...
    'String','Save');

h = resize_gui_elements(h,figure_handle); %resize gui elements according to figure size
set(figure_handle,'ResizeFcn',@resizefigure_call)

%% Finished setting up GUI elements; Now assign GUI start-up settings
h.sub_num = 1;
h.repeat = 1;           %indicates whether to continue looping or stop
h.saved = 1;            %tracks if there have been changes since last save
h.skip_direction = 1;   %direction that index changes when user skips
h.flag.restrict_size = 0;

while ~isfield(h,'S')
    %% Wait until user loads in data structure before proceeding
    guidata(figure_handle,h);
    
    uiwait(figure_handle);
    if ~isvalid(figure_handle)
        h.repeat = 0;
        break
    end
    h = guidata(figure_handle);
end

%% Set-up GUI once data has been loaded
if isvalid(figure_handle)
    %Assign callbacks
    set(h.pn(1).ed(1),'Callback',@changeindex_call);
    set(h.pn(3).pb(1),'Callback',@filterplot_call);
    set(h.pn(3).pb(2),'Callback',@undo_call);
    set(h.pn(4).pb(1),'Callback',@editplot_call);
    set(h.pn(4).pb(2),'Callback',@pn4_pb_call);
    set(h.pn(4).pb(3),'Callback',@pn4_pb_call);
    set(h.pn(4).pb(4),'Callback',@pn4_pb_call);
    set(h.pn(4).pb(5),'Callback',@pn4_pb_call);
    
    %Make plots 1-5 visible and set-up radio buttons 1-5
    for i=1:5
        h.pl(i).Visible = 'On';
        h.pn(2).rb(i).Value = 1;
        set(h.pn(2).rb(i),'Callback',@rb_call);
    end
    
    %Make plots 6-7 invisible and set-up radio buttons 6-7
    for i = 6:7
        h.pl(i).Visible = 'Off';
        h.pn(2).rb(i).Value = 0;
        set(h.pn(2).rb(i),'Callback',@rb_call);
    end
end

while h.repeat
    %% Set-up filter_config (filtering configuration) - use defaults unless filter_config has been previously defined
    h.S(h.sub_num).filter_config.sub_nums = h.sub_num;                  %filter_config.sub_nums should always be h.sub_num;
    if ~isfield(h.S(h.sub_num),'filter_config') || sum(isfield(h.S(h.sub_num).filter_config,{'hann_win','resample_rate','precision','pos_threshold_multiplier','neg_threshold_multiplier','sub_nums'})) ~= 6
        h.S(h.sub_num).filter_config.hann_win = 11;
        h.S(h.sub_num).filter_config.resample_rate = 120;               %120 Hz is the default for Mather Lab's SMI eye-tracker
        h.S(h.sub_num).filter_config.precision = 0.1;                   %100 ms is the tolerance for blink offset to subsequent blink onset
        h.S(h.sub_num).filter_config.pos_threshold_multiplier = 1;
        h.S(h.sub_num).filter_config.neg_threshold_multiplier = 1;
    end
    
    %% Check how many fields already exist and are already populated
    num_fields_exist = sum(isfield(h.S(h.sub_num),{'resampled','velocity','blink_onset','blink_offset','reconstructed'}));
    if num_fields_exist == 5
        num_fields_populated = sum([~isempty(h.S(h.sub_num).resampled),~isempty(h.S(h.sub_num).velocity),~isempty(h.S(h.sub_num).blink_onset),~isempty(h.S(h.sub_num).blink_offset),~isempty(h.S(h.sub_num).reconstructed)]);
    end
    
    %% If necessary, run automated artifact removal algorithm
    if num_fields_exist == 5 && num_fields_populated == 5
        %all fields exist and are already populated with reconstructed data - 
        %do not need to re-run automated artifact removal
    elseif num_fields_exist == 5 && num_fields_populated == 0
        %all fields exist but are NOT yet populated - run automated artifact removal
        h.S = ET_RemoveArtifacts_Auto(h.S,h.S(h.sub_num).filter_config);
    elseif num_fields_exist == 5 && num_fields_populated > 0 && num_fields_populated < 5
        %some fields are missing data - ask user if they want to skip
        %this sub or to re-run automated artifact removal
        h = skip_or_run(h);
        continue
    elseif num_fields_exist == 0
        %fields for reconstructed data do not yet exist - run automated
        %artifact removal
        h.S = ET_RemoveArtifacts_Auto(h.S,h.S(h.sub_num).filter_config);
    elseif num_fields_exist > 0 && num_fields_exist < 5
        %some fields for reconstructed data are missing - ask user if they
        %want to askip this sub or re-run automated artifact removal
        h = skip_or_run(h);
        continue
    end
    
    %% Unpack settings
    h.S(h.sub_num).undo_config = h.S(h.sub_num).filter_config;          %save current config state
    
    %% Update Plots
    h=update_plots(h);
    
    %% Populate Panel 1
    h.pn(1).ed(1).String = num2str(h.sub_num);
    
    %% Populate Panel 3
    h.pn(3).ed(1).String = num2str(h.S(h.sub_num).filter_config.hann_win);
    h.pn(3).ed(2).String = num2str(h.S(h.sub_num).filter_config.resample_rate);
    h.pn(3).ed(3).String = num2str(h.S(h.sub_num).filter_config.precision);
    h.pn(3).ed(4).String = num2str(h.S(h.sub_num).filter_config.pos_threshold_multiplier);
    h.pn(3).ed(5).String = num2str(h.S(h.sub_num).filter_config.neg_threshold_multiplier);
    
    guidata(figure_handle,h);
    
    %% Wait for user interacting with GUI
    uiwait(figure_handle);
    if isvalid(figure_handle)
        h=guidata(figure_handle);
    else
        h.repeat = 0;
    end
    
    S = h.S;                    % S is returned if output is expected
end
end
%% Callback Functions (Figure):
function [] = resizefigure_call(varargin)
%resizes gui elements when user resizes figure

    h = guidata(gcbo);
    figure_handle = gcf;
    
    h=resize_gui_elements(h,figure_handle);

    guidata(gcbo,h);
end

function h = resize_gui_elements(h,figure_handle)
%resizes the elements according to figure dimensions
    
    if figure_handle.Position(3) < 900
        figure_handle.Position(3) = 900;
    end
    if figure_handle.Position(4) < 550
        figure_handle.Position(4) = 550;
    end
    
    %get y dimension of the monitor that the figure is in
    monitor_positions = get(0,'MonitorPositions');
    figure_outerposition = figure_handle.OuterPosition;
    
    monitor_logic_array = monitor_positions(:,1)<figure_outerposition(1)&monitor_positions(:,1)+monitor_positions(:,3)>figure_outerposition(1);
    monitor_y_dim = monitor_positions(monitor_logic_array,4)+monitor_positions(monitor_logic_array,2);       %y dimension of monitor figure is located in
    
    if figure_handle.OuterPosition(2) + figure_handle.OuterPosition(4) > monitor_y_dim
        figure_handle.OuterPosition(2) = monitor_y_dim - figure_handle.OuterPosition(4);
    end
    
    try
    %Adjust axes positions
    h.ax(1).Position = [75 0.5*figure_handle.Position(4)+50 figure_handle.Position(3)-570 0.5*figure_handle.Position(4)-80];
    h.ax(2).Position = [75 50 figure_handle.Position(3)-570 0.5*figure_handle.Position(4)-80];
    
    %Adjust panel positions
    h.pn1.Position = [figure_handle.Position(3)-460, figure_handle.Position(4)-90, 450, 80];
    h.pn2.Position = [figure_handle.Position(3)-460, figure_handle.Position(4)-250, 450, 160];
    h.pn3.Position = [figure_handle.Position(3)-460, figure_handle.Position(4)-410, 450, 160];
    h.pn4.Position = [figure_handle.Position(3)-460, figure_handle.Position(4)-540, 450, 120];
    catch
    %returns if user resizes figure to dimensions that are too small
    end
end

function [] = closefigure_call(varargin)
    h = guidata(gcbo);
    
    if h.saved == 0
    %there have been changes since last save
        resp = questdlg('Closing will discard any unsaved changes!','Continue?','Save','Continue','Cancel','Save');
        switch resp
            case 'Save'
                if ~isfield(h,'file') || ~isfield(h.file,'name') || ~isfield(h.file,'folder')
                    %if file not previously selected, call saveas for user input
                    [return_flag,h] = saveas(h);
                    if return_flag == 1, return; end
                end
                h = savedata(h);            
            case 'Continue'
                %continues to delete figure without saving
            otherwise
                %if user selects cancel or presses x
                return;
        end
    end
    delete(gcf);  
end

%% Callback Functions (Panel 1):
function [] = changeindex_call(varargin)
    h = guidata(gcbo);
    
    edit_value = str2double(h.pn(1).ed(1).String);
    if mod(edit_value,1) == 0
    %if user input an integer
        if edit_value > 0 && edit_value <= numel(h.S)
            h.sub_num = edit_value;
        elseif edit_value < 0
            h.sub_num = 1;
        elseif edit_value > numel(h.S)
            h.sub_num = numel(h.S);
        end
    elseif mod(edit_value,1) ~= 0 || isnan(mod(edit_value,1))
    %if user inputs characters or the number is not an integer - reset
    %h.pn(1).ed(1).String to the previous h.sub_num
        h.pn(1).ed(1).String = h.sub_num;
        guidata(gcbo,h);
        return;
    end
    uiresume(gcf);
    guidata(gcbo,h);    
end
function [] = selectdata_call(varargin)
     h = guidata(gcbo);
     
     %if changes have not been saved, ask if user wants to discard unsaved
     %changes
     if h.saved == 0
         resp = questdlg('Loading new data will discard any unsaved changes. Continue?','Continue?','Yes','No','No');
         switch resp
             case 'Yes'
                 h.sub_num = 1;
             otherwise
                 % if user selects no or presses x
                 return               
         end
     end
     
     if isfield(h,'file') && isfield(h.file,'name') && isfield(h.file,'folder')
        [name, folder] = uigetfile('*.mat','Select File',[h.file.name]);
     else
        [name, folder] = uigetfile('*.mat','Select File');
     end
     
     if ischar(name) && ischar(folder)
         %if user selected an actual file (instead of just canceling)
         h.file.name = name;
         h.file.folder = folder;
         h.pn(1).ed(2).String = name;
         h.saved = 1;
         load(fullfile(folder,name));       %loads variable S
         h.S = S;                           %assign S to h.S
         h.sub_num = 1;                     %reset sub_num to 1
         guidata(gcbo,h);
         uiresume(gcf);
     else
         return;
     end
end

%% Callback Functions (Panel 2):
function [] = rb_call(varargin)
%This callback is for the radiobuttons that control plot visibility
    h = guidata(gcbo);
    cb_obj = gcbo;
    if cb_obj.Value == 1
        on_off = 'On';
    elseif cb_obj.Value == 0
        on_off = 'Off';
    end
    switch cb_obj.Tag
        case 'Velocity'
            h.pl(1).Visible = on_off;
        case 'Velocity_Blink_Onset'
            h.pl(2).Visible = on_off;
        case 'Velocity_Blink_Offset'
            h.pl(3).Visible = on_off;
        case 'Original'
            h.pl(4).Visible = on_off;
        case 'Reconstructed'
            h.pl(5).Visible = on_off;
        case 'Pupil_Blink_Onset'
            h.pl(6).Visible = on_off;
        case 'Pupil_Blink_Offset'
            h.pl(7).Visible = on_off;
    end
    guidata(gcbo,h);
end

%% Callback Functions (Panel 3):
function [] = filterplot_call(varargin)
    h = guidata(gcbo);
    
    if isfield(h.S(h.sub_num),'manual_changes') && ~isempty(h.S(h.sub_num).manual_changes) && h.S(h.sub_num).manual_changes == 1
    %Checks whether manual changes have been made for this plot - if so,
    %user is warned that filter plot will erase any manual changes
        resp = questdlg(['Warning: Filter Plot will undo any manual changes '...
            'that you have made while editting the plot. Are you sure you '...
            'want to continue?'],'Warning','Yes','Cancel','Cancel');
        switch resp
            case 'Yes'
                h.S(h.sub_num).manual_changes = 0;
            otherwise
                %if user selects no or presses x
                return
        end
    end
    
    h.S(h.sub_num).undo_config = h.S(h.sub_num).filter_config;
    h.S(h.sub_num).filter_config.hann_win = str2double(h.pn(3).ed(1).String);
    h.S(h.sub_num).filter_config.resample_rate = str2double(h.pn(3).ed(2).String);
    h.S(h.sub_num).filter_config.precision = str2double(h.pn(3).ed(3).String);
    h.S(h.sub_num).filter_config.pos_threshold_multiplier = str2double(h.pn(3).ed(4).String);
    h.S(h.sub_num).filter_config.neg_threshold_multiplier = str2double(h.pn(3).ed(5).String);
    h.S(h.sub_num).filter_config.sub_nums = h.sub_num;
    h.S = ET_RemoveArtifacts_Auto(h.S,h.S(h.sub_num).filter_config);
    h = update_plots(h);
    h.saved = 0;
    guidata(gcbo,h);
end

function [] = undo_call(varargin)
    h = guidata(gcbo);
    h.S = ET_RemoveArtifacts_Auto(h.S,h.S(h.sub_num).undo_config);
    h = update_plots(h);
    h.pn(3).ed(1).String = num2str(h.S(h.sub_num).undo_config.hann_win);
    h.pn(3).ed(2).String = num2str(h.S(h.sub_num).undo_config.resample_rate);
    h.pn(3).ed(3).String = num2str(h.S(h.sub_num).undo_config.precision);
    h.pn(3).ed(4).String = num2str(h.S(h.sub_num).undo_config.pos_threshold_multiplier);
    h.pn(3).ed(5).String = num2str(h.S(h.sub_num).undo_config.neg_threshold_multiplier);
    h.saved = 0;
    guidata(gcbo,h);
end

function [] = editplot_call(varargin)
    h = guidata(gcbo);
    figure_handle2 = ET_EditArtifacts_Manual_GUI(h);
    if isvalid(figure_handle2)
        h2 = guidata(figure_handle2);
        if h2.save == 1
            % Overwrite data if user selected save
            h.S(h.sub_num).reconstructed.sample = h2.reconstructed.sample;
            h.S(h.sub_num).reconstructed.smp_timestamp = h2.reconstructed.smp_timestamp;
            % Plot newly overwritten data
            h.pl(5).XData = h.S(h.sub_num).reconstructed.smp_timestamp;
            h.pl(5).YData = h.S(h.sub_num).reconstructed.sample;
        end
        delete(figure_handle2);
    end
    h.S(h.sub_num).manual_changes = 1;
    h.saved = 0;
    guidata(gcbo,h);
end

%% Callback Functions (Panel 4):
function [] = pn4_pb_call(varargin)
    h = guidata(gcbo);
    cb_obj = gcbo;
    switch cb_obj.String
        case 'Back'
            if h.sub_num > 1
                h.sub_num = h.sub_num - 1;
                h.skip_direction = -1;      %if user skips, moves sub_num backward
            end
        case 'Next'
            if h.sub_num < numel(h.S)
                h.sub_num = h.sub_num + 1; 
                h.skip_direction = 1;       %if user skips, moves sub_num forward
            end
        case 'Save As'
            [return_flag,h] = saveas(h);
            if return_flag == 1, return; end     
            h = savedata(h);
        case 'Save'
            if ~isfield(h,'file') || ~isfield(h.file,'folder') || ~isfield(h.file,'name')
                %if file not previously selected, call saveas for user input
                [return_flag,h] = saveas(h);
                if return_flag == 1, return; end
            end       
            h = savedata(h);
    end
    h.pn(1).ed(1).String = num2str(h.sub_num);
    guidata(gcbo,h);
    uiresume(gcf);
end

%% Other functions
function [return_flag,h] = saveas(h)
%calls uiputfile to get user to select file name for saving;
%if user exits, return_flag is assigned 1 to notify parent function to
%return
    [name, folder] = uiputfile('*.mat','Save Data Structure S as');
    if ischar(name) && ischar(folder)
        h.file.name = name;
        h.file.folder = folder;
        return_flag = 0;
    else
        return_flag = 1;
    end
end

function h = savedata(h)
%updates edit box in panel 1 to display file name;
%saves current state of data structure in a user-selected file as variable S
    h.pn(1).ed(2).String = h.file.name;
    S = h.S;
    save(fullfile(h.file.folder,h.file.name),'S');
    h.saved = 1;
end

function h = update_plots(h)
%plots/re-plots updated graphs
    h.pl(1).XData = h.S(h.sub_num).velocity.vel_timestamp;
    h.pl(1).YData = h.S(h.sub_num).velocity.velocity;
    h.pl(2).XData = h.S(h.sub_num).blink_onset.vel_timestamp;
    h.pl(2).YData = h.S(h.sub_num).blink_onset.velocity;
    h.pl(3).XData = h.S(h.sub_num).blink_offset.vel_timestamp;
    h.pl(3).YData = h.S(h.sub_num).blink_offset.velocity;

    h.pl(4).XData = h.S(h.sub_num).data.smp_timestamp;
    h.pl(4).YData = h.S(h.sub_num).data.sample;
    h.pl(5).XData = h.S(h.sub_num).reconstructed.smp_timestamp;
    h.pl(5).YData = h.S(h.sub_num).reconstructed.sample;
    h.pl(6).XData = h.S(h.sub_num).blink_onset.smp_timestamp;
    h.pl(6).YData = h.S(h.sub_num).blink_onset.sample;
    h.pl(7).XData = h.S(h.sub_num).blink_offset.smp_timestamp;
    h.pl(7).YData = h.S(h.sub_num).blink_offset.sample;
end

function h = skip_or_run(h)
    resp = questdlg(['Index ' num2str(h.sub_num) ' is missing some '...
        'reconstructed data. Skip index or re-run automated artifact removal?'],...
        'Warning!','Skip','Run','Skip');
    switch resp
        case 'Skip'
            h.sub_num = h.sub_num + h.skip_direction;   %h.skip direction either moves index forward or backward depending on whether back or next was pressed
            if h.sub_num < 1 
            % if user has skipped to the beginning - reset sub_num to end
                h.sub_num = numel(h.S);
            elseif h.sub_num > numel(h.S)
            % if user has skipped to the last index - reset sub_num to 1
                h.sub_num = 1;
            end
        case 'Run'
            h.S = ET_RemoveArtifacts_Auto(h.S,h.S(h.sub_num).filter_config);
    end
end

function [x_pixels,y_pixels] = maximize_figure(handle)
%maximizes figure using JavaFrame property of the figure handle
%returns the x and y dimensions of the figure

    warning('off')
    drawnow;                        %avoids Java Error
    jFig = handle.JavaFrame;
    jFig.setMaximized(true);    
    warning('on')
    pause(0.2)                      %let figure resize first
    x_pixels = handle.Position(3);
    y_pixels = handle.Position(4);
    
end