function figure_handle2 = ET_EditArtifacts_Manual_GUI(h1)
%Allows user to manually edit artifacts from pupil data
%
%Used within ET_ReconstructPlots_GUI.m - After applying the automated
%artifact reconstruction algorithm (ET_RemoveArtifacts_Auto.m), there may
%be some residual artifacts that remain undetected. When user selects the
%"Manually Edit Plot" pushbutton, this function is called to bring up a GUI
%for manually identifying artifacts and interpolating over them
%
%Author: Ringo Huang (ringohua@usc.edu)

figure_handle2 = figure('Position',[100,100,800,500],...
    'Name','Artifact Reconstruction',...
    'WindowStyle','Modal',...
    'Resize','Off');
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
    'Position',[60 60 400 400]);
hold(h2.ax,'on')
h2.pl(1) = plot(h2.data.smp_timestamp,h2.data.sample,'green');
h2.pl(2) = plot(h2.reconstructed.smp_timestamp,h2.reconstructed.sample,'blue');
h2.pl(3) = plot(0,0,'rx');
h2.pl(4) = plot(0,0,'rx');
hold(h2.ax,'off')

h2.ax.XLim = [X_min X_min+h2.increment];
h2.ax.YLim = [0 Y_max];
h2.ax.XTick = X_min:h2.increment/5:X_min+h2.increment;
h2.ax.Title.String = 'Blue = Reconstructed, Green = Original';
h2.ax.XLabel.String = 'Time (Seconds)';
h2.ax.YLabel.String = 'Unknown Units';

%% Set up axes control panel
h2.pn1 = uipanel('Parent',figure_handle2,...
    'Title','Axes Control',...
    'FontSize',10,...
    'Position',[0.61 0.7 0.36 0.15]);
h2.pn(1).sl(1) = uicontrol('Style','slider',...
    'Parent',h2.pn1,...
    'Position',[20 20 20 20],...
    'SliderStep',[1/numel(h2.reconstructed.sample) 1/numel(h2.reconstructed.sample)],...
    'Callback',@slider1_call);
h2.pn(1).ed(1) = uicontrol('Style','edit',...
    'Parent',h2.pn1,...
    'Position',[120 20 30 20],...
    'Tag','XLim1',...
    'String',num2str(h2.ax.XLim(1)),...
    'Callback',@changeaxis_call);
h2.pn(1).ed(2) = uicontrol('Style','edit',...
    'Parent',h2.pn1,...
    'Position',[230 20 30 20],...
    'Tag','XLim2',...
    'String',num2str(h2.ax.XLim(2)),...
    'Callback',@changeaxis_call);
h2.pn(1).tx(1) = uicontrol('Style','text',...
    'Parent',h2.pn1,...
    'FontSize',11,...
    'Position',[70 20 40 20],...
    'String','Min');
h2.pn(1).tx(2) = uicontrol('Style','text',...
    'Parent',h2.pn1,...
    'FontSize',11,...
    'Position',[180 20 40 20],...
    'String','Max');

%% Set up plot editor tools panel
h2.pn2 = uipanel('Parent',figure_handle2,...
    'Title','Plot Editor Tools',...
    'FontSize',10,...
    'Position',[0.61 0.4 0.36 0.25]);
h2.pn(2).ed(1) = uicontrol('Style','Edit',...
    'Parent',h2.pn2,...
    'Units','Normalized',...
    'Position',[0.35 0.68 0.1 0.23]);
h2.pn(2).ed(2) = uicontrol('Style','Edit',...
    'Parent',h2.pn2,...
    'Units','Normalized',...
    'Position',[0.85 0.68 0.1 0.23]);
h2.pn(2).pb(1) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...
    'Units','Normalized',...
    'FontSize',9,...
    'Position',[0.05 0.68 0.25 0.23],...
    'String','Select Start',...
    'Callback',@selectpoint_call);
h2.pn(2).pb(2) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...
    'Units','Normalized',...
    'FontSize',9,...
    'Position',[0.55 0.68 0.25 0.23],...
    'String','Select End',...
    'Callback',@selectpoint_call);
h2.pn(2).pb(3) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...
    'String','Interpolate',...
    'Units','Normalized',...
    'FontSize',9,...
    'Position',[0.1 0.33 0.27 0.23],...
    'Callback',@ploteditor_call);
h2.pn(2).pb(4) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...    
    'String','Re-populate',...
    'Units','Normalized',...
    'FontSize',9,...
    'Position',[0.63 0.33 0.27 0.23],...
    'Callback',@ploteditor_call);
h2.pn(2).pb(5) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...    
    'String','NaN Data',...
    'Units','Normalized',...
    'FontSize',9,...
    'Position',[0.1 0.05 0.27 0.23],...
    'Callback',@ploteditor_call);
h2.pn(2).pb(6) = uicontrol('Style','PushButton',...
    'Parent',h2.pn2,...    
    'String','Undo',...
    'Units','Normalized',...
    'FontSize',9,...
    'Position',[0.63 0.05 0.27 0.23],...
    'Callback',@ploteditor_call);

%% Set up panel 3
h2.pn3 = uipanel('Parent',figure_handle2,...
    'FontSize',10,...
    'Position',[0.61 0.1 0.36 0.25]);
h2.pn(3).pb(1) = uicontrol('Style','PushButton',...
    'Parent',h2.pn3,...
    'String','Save Changes and Exit',...
    'Units','Normalized',...
    'FontSize',9,...
    'Position',[0.1 0.60 0.8 0.23],...
    'Callback',@exit_call);
h2.pn(3).pb(2) = uicontrol('Style','PushButton',...
    'Parent',h2.pn3,...
    'String','Discard Changes and Exit',...
    'Units','Normalized',...
    'FontSize',9,...
    'Position',[0.1 0.20 0.8 0.23],...
    'Callback',@exit_call);

%% Fill the structure with data
h2.current_position = h2.pn(1).sl(1).Value;

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

%% Callback Functions (Panel 1):
function [] = slider1_call(varargin)
    h2=guidata(gcbo);
    
    if h2.pn(1).sl(1).Value > h2.current_position
        change = 1;
    elseif h2.pn(1).sl(1).Value < h2.current_position
        change = -1;
    elseif h2.pn(1).sl(1).Value == h2.current_position
        change = 0;
    end
    h2.current_position = h2.pn(1).sl(1).Value;
    
    % Update x axis
    h2.ax.XLim = h2.ax.XLim + change;
    h2.ax.XTick = h2.ax.XLim(1):h2.increment/5:h2.ax.XLim(2);
    
    % Update X max and X min edit boxes
    h2.pn(1).ed(1).String = num2str(h2.ax.XLim(1));
    h2.pn(1).ed(2).String = num2str(h2.ax.XLim(2));
    
    guidata(gcbo,h2);
end

function [] = changeaxis_call(varargin)
    h2 = guidata(gcbo);
    cb_obj = gcbo;
    
    switch cb_obj.Tag
        case 'XLim1'
            if str2double(h2.pn(1).ed(1).String) >= str2double(h2.pn(1).ed(2).String)
                XLim1 = str2double(h2.pn(1).ed(1).String);
                XLim2 = XLim1 + h2.increment;
            else
                XLim1 = str2double(h2.pn(1).ed(1).String);
                XLim2 = str2double(h2.pn(1).ed(2).String);
                h2.increment = XLim2 - XLim1;
            end
        case 'XLim2'
            if str2double(h2.pn(1).ed(1).String) >= str2double(h2.pn(1).ed(2).String)
                XLim2 = str2double(h2.pn(1).ed(2).String);
                XLim1 = XLim2 - h2.increment;
            else
                XLim1 = str2double(h2.pn(1).ed(1).String);
                XLim2 = str2double(h2.pn(1).ed(2).String);
                h2.increment = XLim2 - XLim1;
            end            
    end
    
    % Update x axis
    h2.ax.XLim = [XLim1,XLim2];
    h2.ax.XTick = h2.ax.XLim(1):h2.increment/5:h2.ax.XLim(2);
    h2.pn(1).ed(1).String = num2str(XLim1);
    h2.pn(1).ed(2).String = num2str(XLim2);
    
    guidata(gcbo,h2);
end

%% Callback Functions (Panel 2):
function [] = selectpoint_call(varargin)
%% Selects endpoints
    h2=guidata(gcbo);
    cb_obj = gcbo;

    %Select data using ginput cursor (WIP: restrict cursor to axes only)
    [x,y] = ginput(1);
    [x,y] = SnapToData([x,y], h2.reconstructed.smp_timestamp, ...
        h2.reconstructed.sample);

    %Update the appropriate fields and plot
    switch cb_obj.String
        case 'Select Start'
            h2.pl(3).XData = x;
            h2.pl(3).YData = y;
            h2.pn(2).ed(1).String = num2str(x);
        case 'Select End'
            h2.pl(4).XData = x;
            h2.pl(4).YData = y;
            h2.pn(2).ed(2).String = num2str(x);
    end
  
    guidata(gcbo,h2);
end

function [] = ploteditor_call(varargin)
%% Makes changes to the plot
    h2 = guidata(gcbo);
    cb_obj = gcbo;
    
    %Before making changes, save the state of the current plot
    if ~strcmp(cb_obj.String,'Undo')
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
    
    switch cb_obj.String
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
    guidata(gcbo,h2);
end

function [x,y] = SnapToData(coordinate, timestamp, dataseries)
%% Nested function for selecting data points
% coordinate is the [x,y] input coordinate collected by ginput
% timestamp is the timestamp array
% dataseries is the data array

[~,index] = min(abs(timestamp-coordinate(1)));
x = timestamp(index);
y = dataseries(index);
end