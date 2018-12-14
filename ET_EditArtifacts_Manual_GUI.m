function figure_handle2 = ET_EditArtifacts_Manual_GUI(h1)
% Allows user to manually edit artifacts from pupil data
%
% Used within ET_ReconstructPlots_GUI.m - After applying the automated
% artifact reconstruction algorithm (ET_RemoveArtifacts_Auto.m), there may
% be some residual artifacts that remain undetected. When user selects the
% "Manually Edit Plot" pushbutton, this function is called to bring up a GUI
% for manually identifying artifacts and interpolating over them
%
% Note: this figure is closed in the "parent" function (i.e.,
% ET_ReconstructPlots_GUI.m). This ensures that data is transferred to the
% "parent" function before the handle to this figure is deleted
%
% Author: Ringo Huang (ringohua@usc.edu)

narginchk(1,1);

figure_handle2 = figure('Position',[100,100,800,500],...
    'Name','Artifact Reconstruction',...
    'WindowStyle','Modal',...
    'WindowKeyPressFcn',@keypress_call,...
    'CloseRequestFcn',@closefigure_call);
set(figure_handle2,'SizeChangedFcn',@resizefigure_call)
h2 = guihandles(figure_handle2);

%% Store data into handle
sub_num = h1.sub_num;
h2.data.smp_timestamp = h1.S(sub_num).data.smp_timestamp;
h2.data.sample = h1.S(sub_num).data.sample;
h2.resampled.smp_timestamp = h1.S(sub_num).resampled.smp_timestamp;
h2.resampled.sample = h1.S(sub_num).resampled.sample;
h2.reconstructed.smp_timestamp = h1.S(sub_num).reconstructed.smp_timestamp;
h2.reconstructed.sample = h1.S(sub_num).reconstructed.sample;

h2.increment = 10;

X_min = floor(min(h2.data.smp_timestamp));
X_max = max(h2.data.smp_timestamp);
Y_min = min(h2.data.sample);
Y_max = max(h2.data.sample);

%% Set up axes
h2.ax = axes('Parent',figure_handle2,...
    'Units','Pixels',...
    'Position',[60 60 figure_handle2.Position(3)-390 figure_handle2.Position(4)-100]);
hold(h2.ax,'on')
h2.pl(1) = plot(h2.data.smp_timestamp,h2.data.sample,'green');
h2.pl(2) = plot(h2.reconstructed.smp_timestamp,h2.reconstructed.sample,'blue');
h2.pl(3) = plot(0,0,'rx');
h2.pl(4) = plot(0,0,'rx');
hold(h2.ax,'off')

h2.ax.XLim = [X_min X_min+h2.increment];
h2.ax.YLim = [0 Y_max];
h2.ax.Title.String = 'Blue = Reconstructed, Green = Original';
h2.ax.XLabel.String = 'Time (Seconds)';
h2.ax.YLabel.String = 'Unknown Units';

%% Set up axes control panel
h2.pn1 = uipanel('Parent',figure_handle2,...
    'Units','Pixels',...
    'Title','Axes Control',...
    'FontSize',10,...
    'Position',[figure_handle2.Position(3)-300 figure_handle2.Position(4)-160 280 140]);
%Set-up x-coordinate objects
h2.pn(1).sl(1) = uicontrol('Style','slider',...
    'Parent',h2.pn1,...
    'Position',[50 80 20 25],...
    'SliderStep',[1/numel(h2.reconstructed.sample) 1/numel(h2.reconstructed.sample)],...
    'Tag','xslider',...
    'Callback',@slider_call);
h2.pn(1).ed(1) = uicontrol('Style','edit',...
    'Parent',h2.pn1,...
    'Position',[140 80 30 20],...
    'Tag','XLim1',...
    'String',num2str(h2.ax.XLim(1)),...
    'Callback',@changeaxis_call);
h2.pn(1).ed(2) = uicontrol('Style','edit',...
    'Parent',h2.pn1,...
    'Position',[220 80 30 20],...
    'Tag','XLim2',...
    'String',num2str(h2.ax.XLim(2)),...
    'Callback',@changeaxis_call);
h2.pn(1).tx(1) = uicontrol('Style','text',...
    'Parent',h2.pn1,...
    'FontSize',11,...
    'Position',[25 80 15 20],...
    'String','x');
h2.pn(1).tx(2) = uicontrol('Style','text',...
    'Parent',h2.pn1,...
    'FontSize',10,...
    'Position',[100 80 40 20],...
    'String','Min');
h2.pn(1).tx(3) = uicontrol('Style','text',...
    'Parent',h2.pn1,...
    'FontSize',10,...
    'Position',[180 80 40 20],...
    'String','Max');

%Set-up y-coordinate objects
h2.pn(1).sl(2) = uicontrol('Style','slider',...
    'Parent',h2.pn1,...
    'Position',[50 25 20 25],...
    'SliderStep',[1/numel(h2.reconstructed.sample) 1/numel(h2.reconstructed.sample)],...
    'Tag','yslider',...
    'Callback',@slider_call);
h2.pn(1).ed(3) = uicontrol('Style','edit',...
    'Parent',h2.pn1,...
    'Position',[140 25 30 20],...
    'Tag','YLim1',...
    'String',num2str(h2.ax.XLim(1)),...
    'Callback',@changeaxis_call);
h2.pn(1).ed(4) = uicontrol('Style','edit',...
    'Parent',h2.pn1,...
    'Position',[220 25 30 20],...
    'Tag','YLim2',...
    'String',num2str(h2.ax.XLim(2)),...
    'Callback',@changeaxis_call);
h2.pn(1).tx(4) = uicontrol('Style','text',...
    'Parent',h2.pn1,...
    'FontSize',11,...
    'Position',[25 25 15 20],...
    'String','y');
h2.pn(1).tx(5) = uicontrol('Style','text',...
    'Parent',h2.pn1,...
    'FontSize',10,...
    'Position',[100 25 40 20],...
    'String','Min');
h2.pn(1).tx(6) = uicontrol('Style','text',...
    'Parent',h2.pn1,...
    'FontSize',10,...
    'Position',[180 25 40 20],...
    'String','Max');

%% Set up plot editor tools panel
h2.pn2 = uipanel('Parent',figure_handle2,...
    'Units','Pixels',...
    'Title','Plot Editor Tools',...
    'FontSize',10,...
    'Position',[figure_handle2.Position(3)-300 figure_handle2.Position(4)-350 280 180]);
h2.pn(2).ed(1) = uicontrol('Style','Edit',...
    'Parent',h2.pn2,...
    'Units','Pixels',...
    'Position',[100 125 30 25]);
h2.pn(2).ed(2) = uicontrol('Style','Edit',...
    'Parent',h2.pn2,...
    'Units','Pixels',...
    'Position',[235 125 30 25]);
h2.pn(2).pb(1) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...
    'Units','Pixels',...
    'FontSize',9,...
    'Position',[15 125 75 25],...
    'String','Select Start',...
    'Callback',@selectpoint_call);
h2.pn(2).pb(2) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...
    'Units','Pixels',...
    'FontSize',9,...
    'Position',[150 125 75 25],...
    'String','Select End',...
    'Callback',@selectpoint_call);
h2.pn(2).pb(3) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...
    'String','Interpolate',...
    'Units','Pixels',...
    'FontSize',9,...
    'Position',[40 50 75 25],...
    'Callback',@ploteditor_call);
h2.pn(2).pb(4) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...    
    'String','Re-populate',...
    'Units','Pixels',...
    'FontSize',9,...
    'Position',[150 50 75 25],...
    'Callback',@ploteditor_call);
h2.pn(2).pb(5) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...    
    'String','NaN Data',...
    'Units','Pixels',...
    'FontSize',9,...
    'Position',[40 15 75 25],...
    'Callback',@ploteditor_call);
h2.pn(2).pb(6) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...    
    'String','Undo',...
    'Units','Pixels',...
    'FontSize',9,...
    'Position',[150 15 75 25],...
    'Callback',@ploteditor_call);

%% Set up panel 3
h2.pn3 = uipanel('Parent',figure_handle2,...
    'Units','Pixels',...
    'FontSize',10,...
    'Position',[figure_handle2.Position(3)-300 figure_handle2.Position(4)-485 280 120]);
h2.pn(3).pb(1) = uicontrol('Style','PushButton',...
    'Parent',h2.pn3,...
    'String','Save Changes and Exit',...
    'Units','Pixels',...
    'FontSize',9,...
    'Position',[30 70 220 25],...
    'Callback',@exit_call);
h2.pn(3).pb(2) = uicontrol('Style','PushButton',...
    'Parent',h2.pn3,...
    'String','Discard Changes and Exit',...
    'Units','Pixels',...
    'FontSize',9,...
    'Position',[30 25 220 25],...
    'Callback',@exit_call);

%% Fill the structure with data
h2.pn(1).sl(1).UserData = h2.pn(1).sl(1).Value;
h2.pn(1).sl(2).UserData = h2.pn(1).sl(2).Value;

h2.XLM = get(h2.ax,'xlim');
h2.YLM = get(h2.ax,'ylim');
h2.AXP = get(h2.ax,'pos');
h2.DFX = diff(h2.XLM);
h2.DFY = diff(h2.YLM);

%% Wait for user to finish interacting with GUI
guidata(figure_handle2,h2);
uiwait(figure_handle2);

end

%% Callback Functions
function [] = keypress_call(varargin)
    h2 = guidata(gcf);
    key_data = varargin{2};
    
    switch key_data.Key
        case 'a'
            change = -1;
            h2 = UpdateXAxis(h2,change);
        case 'd'
            change = 1;
            h2 = UpdateXAxis(h2,change);
        case 's'
            change = -1;
            h2 = UpdateYAxis(h2,change);
        case 'w'
            change = 1;
            h2 = UpdateYAxis(h2,change);
        case 'q'
            h2 = SelectStart(h2);
        case 'e'
            h2 = SelectEnd(h2);
        case 'z'
            h2 = EditPlot(h2,'Interpolate');
        case 'x'
            h2 = EditPlot(h2,'Re-populate');
        case 'c'
            h2 = EditPlot(h2,'NaN Data');
            
    end
    guidata(gcf, h2);
end
function [] = resizefigure_call(varargin)
%Plot expands as figure enlarges
    h2 = guidata(gcbo);
    figure_handle2 = gcf;
    
    try
    h2.ax.Position = [60 60 figure_handle2.Position(3)-390 figure_handle2.Position(4)-100];
    h2.pn1.Position = [figure_handle2.Position(3)-300 figure_handle2.Position(4)-160 280 140];
    h2.pn2.Position = [figure_handle2.Position(3)-300 figure_handle2.Position(4)-350 280 180];
    h2.pn3.Position = [figure_handle2.Position(3)-300 figure_handle2.Position(4)-485 280 120];
    catch
        %returns if user resizes figure to a dimension that is too small
    end
    
    guidata(gcbo,h2);
end

function [] = exit_call(varargin)
% either saves or discards changes
    h2 = guidata(gcbo);
    cb_obj = gcbo;
    
    switch cb_obj.String
        case 'Save Changes and Exit'
            h2.save = 1;
        case 'Discard Changes and Exit'
            h2.save = 0;
    end
    uiresume(gcbf);
    guidata(gcbo,h2);   
end

function [] = closefigure_call(varargin)
    
    resp = questdlg('Warning: Changes will be discarded if you continue.','Warning','Continue','Cancel','Cancel');
    
    switch resp
        case 'Continue'
            h2.save = 0;
            uiresume(gcbf);
            guidata(gcbo,h2);
        case 'Cancel'
            return
    end
end


%% Callback Functions (Panel 1):
function [] = slider_call(varargin)
%UserData of the slider objects contains the previous Value  
    cb_obj = gcbo;
    h2=guidata(cb_obj);
    
    %change tick mode back to manual
    h2.ax.XTickMode = 'manual';
    h2.ax.YTickMode = 'manual';
    
    if cb_obj.Value > cb_obj.UserData
        change = 1;
    elseif cb_obj.Value < cb_obj.UserData
        change = -1;
    elseif cb_obj.Value == cb_obj.UserData
        change = 0;
    end
    cb_obj.UserData = cb_obj.Value;
    
    switch cb_obj.Tag
        case 'xslider'
            % Update x axis
            h2.ax.XLim = h2.ax.XLim + change;
            % Update x tick
            increment = h2.ax.XTick(2)-h2.ax.XTick(1);
            if h2.ax.XLim(1) <= h2.ax.XTick(1)-increment
                h2.ax.XTick = [h2.ax.XTick(1)-increment h2.ax.XTick];
            elseif h2.ax.XLim(2) >= h2.ax.XTick(end)+increment
                h2.ax.XTick = [h2.ax.XTick h2.ax.XTick(end)+increment];
            end
            % Update X max and X min edit boxes
            h2.pn(1).ed(1).String = num2str(h2.ax.XLim(1));
            h2.pn(1).ed(2).String = num2str(h2.ax.XLim(2));
        case 'yslider'
            % Update y axis
            h2.ax.YLim = h2.ax.YLim + change;
            % Update y tick
            increment = h2.ax.YTick(2)-h2.ax.YTick(1);
            if h2.ax.YLim(1) <= h2.ax.YTick(1)-increment
                h2.ax.YTick = [h2.ax.YTick(1)-increment h2.ax.YTick];
            elseif h2.ax.YLim(2) >= h2.ax.YTick(end)+increment
                h2.ax.YTick = [h2.ax.YTick h2.ax.YTick(end)+increment];
            end
            % Update Y max and Y min edit boxes
            h2.pn(1).ed(3).String = num2str(h2.ax.YLim(1));
            h2.pn(1).ed(4).String = num2str(h2.ax.YLim(2));
    end
    
    guidata(gcbo,h2);
end

function [] = changeaxis_call(varargin)
%Behavior: if user inputs a min that is greater than the max, the axes
%advances to the new min, and the max is min + the previous difference
    h2 = guidata(gcbo);
    cb_obj = gcbo;
    
    switch cb_obj.Tag
        case 'XLim1'
            if str2double(h2.pn(1).ed(1).String) >= str2double(h2.pn(1).ed(2).String)
                increment = h2.ax.XLim(2) - h2.ax.XLim(1);
                XLim1 = str2double(h2.pn(1).ed(1).String);
                XLim2 = XLim1 + increment;
            else
                XLim1 = str2double(h2.pn(1).ed(1).String);
                XLim2 = str2double(h2.pn(1).ed(2).String);
            end
        case 'XLim2'
            if str2double(h2.pn(1).ed(1).String) >= str2double(h2.pn(1).ed(2).String)
                increment = h2.ax.XLim(2) - h2.ax.XLim(1);
                XLim2 = str2double(h2.pn(1).ed(2).String);
                XLim1 = XLim2 - increment;
            else
                XLim1 = str2double(h2.pn(1).ed(1).String);
                XLim2 = str2double(h2.pn(1).ed(2).String);
            end
        case 'YLim1'
            if str2double(h2.pn(1).ed(3).String) >= str2double(h2.pn(1).ed(4).String)
                increment = h2.ax.YLim(2) - h2.ax.YLim(1);
                YLim1 = str2double(h2.pn(1).ed(3).String);
                YLim2 = YLim1 + increment;
            else
                YLim1 = str2double(h2.pn(1).ed(3).String);
                YLim2 = str2double(h2.pn(1).ed(4).String);
            end
        case 'YLim2'
            if str2double(h2.pn(1).ed(3).String) >= str2double(h2.pn(1).ed(4).String)
                increment = h2.ax.YLim(2) - h2.ax.YLim(1);
                YLim2 = str2double(h2.pn(1).ed(4).String);
                YLim1 = YLim2 - increment;
            else
                YLim1 = str2double(h2.pn(1).ed(3).String);
                YLim2 = str2double(h2.pn(1).ed(4).String);
            end
    end
    
    % Update axes
    if strcmp(cb_obj.Tag,'XLim1') || strcmp(cb_obj.Tag,'XLim2')
        h2.ax.XLim = [XLim1,XLim2];
        h2.ax.XTickMode = 'auto';
        h2.pn(1).ed(1).String = num2str(XLim1);
        h2.pn(1).ed(2).String = num2str(XLim2);
    elseif strcmp(cb_obj.Tag,'YLim1') || strcmp(cb_obj.Tag,'YLim2')
        h2.ax.YLim = [YLim1,YLim2];
        h2.pn(1).ed(3).String = num2str(YLim1);
        h2.pn(1).ed(4).String = num2str(YLim2);
    end
    
    guidata(gcbo,h2);
end

%% Callback Functions (Panel 2):
function [] = selectpoint_call(varargin)
%% Selects endpoints
    h2=guidata(gcbo);
    cb_obj = gcbo;
    
    %Select start/end point on plot and updates the appropriate edit boxes
    switch cb_obj.String
        case 'Select Start'
            h2 = SelectStart(h2);
        case 'Select End'
            h2 = SelectEnd(h2);
    end
  
    guidata(gcbo,h2);
end

function [] = ploteditor_call(varargin)
%% Callback for the different pushbuttons (4 options for editing the plot)
    h2 = guidata(gcbo);
    cb_obj = gcbo;
    action = cb_obj.String;
    h2 = EditPlot(h2,action);
    guidata(gcbo,h2);
end

%% Functions:
function h2 = SelectStart(h2)
%Select data using ginput cursor (WIP: restrict cursor to axes only)
[x,y] = ginput(1);
[x,y] = SnapToData([x,y], h2.reconstructed.smp_timestamp, ...
    h2.reconstructed.sample);
h2.pl(3).XData = x;
h2.pl(3).YData = y;
h2.pl(3).Color = [0 0.5 0];
h2.pl(3).MarkerSize = 8;
h2.pl(3).LineWidth = 1.5;
h2.pn(2).ed(1).String = num2str(x);
end
function h2 = SelectEnd(h2)
%Select data using ginput cursor (WIP: restrict cursor to axes only)
[x,y] = ginput(1);
[x,y] = SnapToData([x,y], h2.reconstructed.smp_timestamp, ...
    h2.reconstructed.sample);
h2.pl(4).XData = x;
h2.pl(4).YData = y;
h2.pl(4).Color = [0.5 0 0];
h2.pl(4).MarkerSize = 8;
h2.pl(4).LineWidth = 1.5;
h2.pn(2).ed(2).String = num2str(x);
end
function h2 = EditPlot(h2,action)
%% Makes changes to the plot depending on the action
    %Before making changes, save the state of the current plot
    if ~strcmp(action,'Undo')
        h2.data.sample_temp = h2.reconstructed.sample;
        h2.data.smp_timestamp_temp = h2.reconstructed.smp_timestamp;
    end
    
    %Find the selected end points
    start_index = find(h2.reconstructed.smp_timestamp==h2.pl(3).XData,1);
    end_index = find(h2.reconstructed.smp_timestamp==h2.pl(4).XData,1);
    if start_index >= end_index
        msgbox(['Your start point cannot occur after your end point.' ....
            'Please reselect your start and end points.'],'Reselect Points');
        return
    end
    
    switch action
        case 'Interpolate'
            t2 = start_index;  %t2 is the smaller of the two endpoints
            t3 = end_index;  %t3 is the larger of the two endpoints
            t1 = t2-t3+t2;
            t4 = t3-t2+t3;
            if t1 <= 0, t1 = 1; end     %make sure t1 is a valid x value
            if t4 > numel(h2.reconstructed.sample), t4 = numel(h2.reconstructed.sample); end
            x = [t1,t2,t3,t4];
            v = [h2.reconstructed.sample(t1),h2.reconstructed.sample(t2),h2.reconstructed.sample(t3),h2.reconstructed.sample(t4)];
            xq = t2:t3;
            vq = interp1(x,v,xq,'linear');         
            h2.reconstructed.sample(t2:t3) = vq;
        case 'Re-populate'
            h2.reconstructed.sample(start_index:end_index) = h2.resampled.sample(start_index:end_index);
        case 'NaN Data'
            h2.reconstructed.sample(start_index:end_index) = NaN;
        case 'Undo'
            h2.reconstructed.sample = h2.data.sample_temp;
            h2.reconstructed.smp_timestamp = h2.data.smp_timestamp_temp;
    end
    
    %Replot new data
    h2.pl(2).YData = h2.reconstructed.sample;
end

function h2 = UpdateXAxis(h2,change)
%% Updates the x axes

% Update x axis
h2.ax.XLim = h2.ax.XLim + change;
% Update x tick
increment = h2.ax.XTick(2)-h2.ax.XTick(1);
if h2.ax.XLim(1) <= h2.ax.XTick(1)-increment
    h2.ax.XTick = [h2.ax.XTick(1)-increment h2.ax.XTick];
elseif h2.ax.XLim(2) >= h2.ax.XTick(end)+increment
    h2.ax.XTick = [h2.ax.XTick h2.ax.XTick(end)+increment];
end
% Update X max and X min edit boxes
h2.pn(1).ed(1).String = num2str(h2.ax.XLim(1));
h2.pn(1).ed(2).String = num2str(h2.ax.XLim(2));
end
function h2 = UpdateYAxis(h2,change)
%% Updates the y axes

% Update y axis
h2.ax.YLim = h2.ax.YLim + change;
% Update y tick
increment = h2.ax.YTick(2)-h2.ax.YTick(1);
if h2.ax.YLim(1) <= h2.ax.YTick(1)-increment
    h2.ax.YTick = [h2.ax.YTick(1)-increment h2.ax.YTick];
elseif h2.ax.YLim(2) >= h2.ax.YTick(end)+increment
    h2.ax.YTick = [h2.ax.YTick h2.ax.YTick(end)+increment];
end
% Update Y max and Y min edit boxes
h2.pn(1).ed(3).String = num2str(h2.ax.YLim(1));
h2.pn(1).ed(4).String = num2str(h2.ax.YLim(2));
end
function [x,y] = SnapToData(coordinate, timestamp, dataseries)
%% Selects and snaps to closest data point
% coordinate is the [x,y] input coordinate collected by ginput
% timestamp is the timestamp array
% dataseries is the data array

[~,index] = min(abs(timestamp-coordinate(1)));
x = timestamp(index);
y = dataseries(index);
end