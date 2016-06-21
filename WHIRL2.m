function WHIRL2
close all
% Description: Adaption of whirl.m written by Dr. Matthew Kay to a 
% graphical user interface for designating silhouettes of panoramic imaging 
% geometry.
%
% Author: Christopher Gloschat
% Date: June 20, 2016


%% Create GUI structure
% scrnSize = get(0,'ScreenSize');
pR = figure('Name','WHIRL 2.0','Visible','off',...
    'Position',[1 1 540 800],'NumberTitle','Off');
% Screens for anlayzing data
axesSize = 500;
silhView = axes('Parent',pR,'Units','Pixels','YTick',[],'XTick',[],...
    'Position',[20 280 axesSize axesSize]);

% Selection of home directory
hDirButton = uicontrol('Parent',pR,'Style','pushbutton','String','Home Directory',...
    'FontSize',12,'Position',[25 250 100 20],'Callback',{@hDirButton_callback});
hDirTxt = uicontrol('Parent',pR,'Style','edit','String','','FontSize',11,...
    'Enable','off','HorizontalAlignment','Left','Position',[130 250 390 20]);
% Selection of image directory
iDirButton = uicontrol('Parent',pR,'Style','pushbutton','String','Image Directory',...
    'FontSize',12,'Position',[25 220 100 20],'Callback',{@iDirButton_callback});
iDirTxt = uicontrol('Parent',pR,'Style','edit','String','','FontSize',12,...
    'Enable','off','HorizontalAlignment','Left','Position',[130 220 390 20]);

% Rotation and images settings for analysis
degreeTxt = uicontrol('Parent',pR,'Style','text','String','Degrees Per Step:',...
    'HorizontalAlignment','Right','FontSize',12,'Position',[20 190 105 20]);
degreeEdit = uicontrol('Parent',pR,'Style','edit','String','5',...
    'FontSize',12,'Position',[130 190 40 20],'Callback',{@degreeEdit_callback});
imagesTxt = uicontrol('Parent',pR,'Style','text','String','Images Acquired:',...
    'HorizontalAlignment','Right','FontSize',12,'Position',[20 160 105 20]);
imagesEdit = uicontrol('Parent',pR,'Style','edit','String','72',...
    'FontSize',12,'Position',[130 160 40 20],'Callback',{@imagesEdit_callback});

% Threshold value
threshTxt = uicontrol('Parent',pR,'Style','text','String','Threshold Value:',...
    'FontSize',12,'HorizontalAlignment','Right','Position',[315 70 105 20]);
threshEdit = uicontrol('Parent',pR,'Style','edit','String','0.350',...
    'FontSize',12,'Position',[425 70 40 20],'Callback',{@threshEdit_callback});
threshApply = uicontrol('Parent',pR,'Style','pushbutton','String','Apply',...
    'FontSize',12,'Position',[470 70 40 20],'Callback',{@threshApply_callback});
threshAdd = uicontrol('Parent',pR,'Style','pushbutton','String','Add',...
    'FontSize',12,'Position',[425 40 40 20],'Callback',{@threshAdd_callback});
threshMinus = uicontrol('Parent',pR,'Style','pushbutton','String',...
    'Minus','FontSize',12,'Position',[470 40 40 20],'Callback',{@threshMinus_callback});

% Load background images
loadBkgdButton = uicontrol('Parent',pR,'Style','pushbutton','String',...
    'Load Backgrounds','FontSize',12,'Position',[25 70 145 20],...
    'Callback',{@loadBkgdButton_callback});

% Above or below threshold designation
abThreshPop = uicontrol('Parent',pR,'Style','popupmenu','String',...
    {'Above','Below'},'Position',[65 100 112 20],'Callback',...
    {@abThreshPop_callback});

% Switch between images
imNumEdit = uicontrol('Parent',pR,'Style','edit','FontSize',12,...
    'String','1','Position',[225 70 40 20],'Callback',{@imNumEdit_callback});
imNumInc = uicontrol('Parent',pR,'Style','pushbutton','FontSize',12,...
    'String',char(8594),'Position',[270 70 40 20],'Callback',{@imNumInc_callback});
imNumDec = uicontrol('Parent',pR,'Style','pushbutton','FontSize',12,...
    'String',char(8592),'Position',[180 70 40 20],'Callback',{@imNumDec_callback});

% Message center text box
msgCenter = uicontrol('Parent',pR,'Style','text','String','','FontSize',...
    12,'Position',[180 130 340 80]);

% Allow all GUI structures to be scaled when window is dragged
set([pR,silhView,hDirButton,hDirTxt,degreeTxt,degreeEdit,imagesTxt,imagesEdit,...
    threshTxt,threshEdit,loadBkgdButton,msgCenter,abThreshPop,iDirButton,...
    iDirTxt,imNumEdit,imNumInc,imNumDec,threshApply,threshAdd,threshMinus],...
    'Units','normalized')

% Center GUI on screen
movegui(pR,'center')
set(pR,'MenuBar','none','Visible','on')

%% Create handles
handles.hdir = [];
handles.bdir = [];
handles.dtheta = str2double(get(degreeEdit,'String'));
handles.n_images = str2double(get(imagesEdit,'String'));
handles.oldDir = pwd;
handles.fileList = [];
handles.sfilename = [];
handles.ndigits = [];
handles.def_thresh = str2double(get(threshEdit,'String'));
handles.aabb = str2double(get(threshEdit,'String'));
handles.thresharr = zeros(1,handles.n_images);
handles.loadClicked = 0;
handles.currentImage = 1;
handles.silhs = [];


%% Select the directory with the heart background images
    function hDirButton_callback(~,~)
         % select experimental directory
        handles.hdir = uigetdir;
        % populate text field
        set(hDirTxt,'String',handles.hdir)
        % change directory
        cd(handles.hdir)
    end

%% Select image directory
function iDirButton_callback(~,~)
         % select experimental directory
        handles.bdir = uigetdir;        
        % populate text field
        set(iDirTxt,'String',['...' handles.bdir(length(handles.hdir)+1:end)])
        % change directory
        cd(handles.bdir)
        % list of files in the directory
        fileList = dir;
        % check which list items are directories and which are files
        checkFiles = zeros(size(fileList,1),1);
        for n = 1:length(checkFiles)
           checkFiles(n) = fileList(n).isdir; 
        end
        % grab indices of the files that are directories
        checkFiles = checkFiles.*(1:length(checkFiles))';
        checkFiles = unique(checkFiles);
        checkFiles = checkFiles(2:end);
        % remove directories from file list
        fileList(checkFiles) = [];
        
        % identify period that separates the name and file type
        charCheck = zeros(length(fileList(1).name),1);
        for n = 1:length(charCheck)
            % char(46) is a period
           charCheck(n) = fileList(1).name(n) == char(46);
           if charCheck(n) == 1
               middleInd = n;
               break
           end
        end
        % assign the file type
        handles.sfilename = fileList(1).name(middleInd+1:end);
        
        % identify numeric portion of filenames
        nameInd = 1:middleInd-1;
        numCheck = 48:57;
        nameInd = repmat(nameInd,[length(numCheck) 1]);
        numCheck = repmat(numCheck',[1 size(nameInd,2)]);
        numCheck = fileList(1).name(nameInd) == char(numCheck);
        numCheck = sum(numCheck).*(1:size(nameInd,2));
        numCheck = unique(numCheck);
        if length(numCheck) > 1
            numCheck = numCheck(2:end);
        end
        % number of digits in filenames
        handles.ndigits = length(numCheck);
        
        % assign filename
        handles.bfilename = fileList(1).name(1:numCheck(1)-1);
        
        % assign start number for the silhouettes files
        handles.sdigit = fileList(1).name(numCheck(end));
        
        % save out filenames
        handles.fileList = fileList;
        
        % preallocate space for silhouettes
        
    end

%% Set the number of degrees per step
    function degreeEdit_callback(source,~)
        if isnan(str2double(source.String))
            errordlg('Value must be positive and numeric','Invalid Input')
            set(degreeEdit,'String','')
        elseif str2double(source.String) <= 0
            errordlg('Value must be positive and numeric','Invalid Input')
            set(degreeEdit,'String','')
        else
           handles.dtheta = str2double(source.String); 
        end
    end

%% Set the number of background images acquired
    function imagesEdit_callback(source,~)
        if isnan(str2double(source.String))
            errordlg('Value must be positive and numeric','Invalid Input')
            set(imagesEdit,'String','')
        elseif str2double(source.String) <= 0
            errordlg('Value must be positive and numeric','Invalid Input')
            set(imagesEdit,'String','')
        else
           handles.n_images = str2double(source.String); 
        end
    end

%% Set the threshold for identifying the silhouettes
    function threshEdit_callback(source,~)
        if isnan(str2double(source.String))
            errordlg('Value must be positive and numeric','Invalid Input')
            set(threshEdit,'String','')
        elseif str2double(source.String) <= 0
            errordlg('Value must be positive and numeric','Invalid Input')
            set(threshEdit,'String','')
        else
           handles.def_thresh = str2double(source.String);
           handles.thresharr = handles.thresharr + handles.def_thresh;
        end
    end

%% Apply threshold to images
    function threshApply_callback(~,~)
            % Clear axes
            cla(silhView)
            % Plot image to axes
            fname = handles.fileList(handles.currentImage).name;
            a = imread(fname);
            a = rgb2gray(a);
            a = double(a);
            handles.a = a/max(max(a(:,:,1)));
            axes(silhView)
            imagesc(handles.a)
            colormap('gray')
            set(silhView,'XTick',[],'YTick',[])
            % Calculate the outline based on the specified threshold settings
            [bw] = calcSilh(handles.a,handles.def_thresh,handles.aabb);
            handles.silhs(:,:,handles.currentImage) = bw;
            % Find outline and superimpose on image
            outline = bwperim(bw,8);
            [or,oc]=find(outline);
            axes(silhView)
            hold on
            plot(oc,or,'y.');
            hold off
    end

%% Add to the silhouette
    function threshAdd_callback(~,~)
        % Define region to add to silhouette
        axes(silhView)
        add = roipoly;
        bw = handles.silhs(handles.currentImage);
        bw = bw + add;
        
        % Replot image
        cla(silhView)
        axes(silhView)
        imagesc(handles.a)
        colormap('gray')
        set(silhView,'XTick',[],'YTick',[])
        
        % Calculate and  plot new outline
        outline = bwperim(bw,8);
        [or,oc]=find(outline);
        axes(silhView)
        hold on
        plot(oc,or,'y.');
        hold off
    end

%% Subtract from the silhouette
    function threshMinus_callback(~,~)
        
    end

%% Above or below threshold
    function abThreshPop_callback(source,~)
        if source.Value == 1
            handles.aabb = 1;
        else
            handles.aabb = 0;
        end
    end

%% Load background images
    function loadBkgdButton_callback(~,~)
        % Check for already established threshold values
        cd(handles.hdir)
        fid=fopen('thresharr.dat');
        if fid~=-1
            set(msgCenter,'String','Found thresharr.dat!');
            fclose(fid);
            isthresh=1;
        else
            set(msgCenter,'String','Could not find thresharr.dat!');
            isthresh=0;
        end
        
        % Change current directory to heart geometry directory
        cd(handles.bdir)
        
        % Load thresholds or set a default threshold
        if isthresh
            pickThresh = questdlg('FOUND THRESHARR.DAT! USE OLD THRESHOLDS OR ESTABLISH NEW ONES?',...
                'Old vs. New','OLD','NEW','OLD');
            % Handle response
            switch pickThresh
                case 'OLD'
                    loadthresh = 1;
                case 'NEW'
                    loadthresh = 0;
            end
        end
        
        % Determine thresholds four silhouettes
        if loadthresh
            % Load established thresholds
            load('thresharr.dat')
        % Establish thresholds
        else  
            % Plot image to axes
            fname = handles.fileList(handles.currentImage).name;
            a = imread(fname);
            a = rgb2gray(a);
            a = double(a);
            handles.a = a/max(max(a(:,:,1)));
            axes(silhView)
            imagesc(handles.a)
            colormap('gray')
            set(silhView,'XTick',[],'YTick',[])
        end
        
        % Preallocate space for silhouettes
        handles.silhs = zeros(size(handles.a,1),size(handles.a,2),...
            size(handles.thresharr,2));
        
        % Calculate the outline based on the specified threshold settings
        [bw] = calcSilh(handles.a,handles.def_thresh,handles.aabb);
        handles.silhs(:,:,handles.currentImage) = bw;
        % Find outline and superimpose on image
        outline = bwperim(bw,8);
        [or,oc]=find(outline);
        axes(silhView)
        hold on
        plot(oc,or,'y.');
        hold off
        
        % Disable button
        set(loadBkgdButton,'Enable','off')
        handles.loadClicked = 1;
                  
    end

%% Callback for manually changing image number %%
    function imNumEdit_callback(source,~)
        % Grab edit box value
        val = str2double(get(source,'String'));
        if ~isnumeric(val) || isnan(val)
            set(imNumEdit,'String',num2str(handles.currentImage))
            msgbox('Must enter a positive numeric value.','Error','error')
        elseif val < 0
            set(imNumEdit,'String',num2str(handles.currentImage))
            msgbox('Must enter a positive numeric value.','Error','error')
        elseif val > handles.n_images
            set(imNumEdit,'String',num2str(handles.currentImage))
            msgbox('Must enter a value equal to or less than total number of images.',...
                'Error','error')
        else
            % Update current image value
            handles.currentImage = val;
            % Update silhouette window
            if handles.loadClicked
                % Clear axes
                cla(silhView)
                % Plot image to axes
                fname = handles.fileList(handles.currentImage).name;
                a = imread(fname);
                a = rgb2gray(a);
                a = double(a);
                handles.a = a/max(max(a(:,:,1)));
                axes(silhView)
                imagesc(handles.a)
                colormap('gray')
                set(silhView,'XTick',[],'YTick',[])
                % Calculate the outline based on the specified threshold settings
                [bw] = calcSilh(handles.a,handles.def_thresh,handles.aabb);
                handles.silhs(:,:,handles.currentImage) = bw;
                % Find outline and superimpose on image
                outline = bwperim(bw,8);
                [or,oc]=find(outline);
                axes(silhView)
                hold on
                plot(oc,or,'y.');
                hold off
            end
        end
    end

%% Callback for incrementing image number
    function imNumInc_callback(~,~)
        % Update current image tracker
        val = handles.currentImage;
        if val+1 > handles.n_images
            handles.currentImage = 1;
            set(imNumEdit,'String',num2str(handles.currentImage))
        else
            handles.currentImage = val+1;
            set(imNumEdit,'String',num2str(handles.currentImage))
        end
        % Update silhouette window
        if handles.loadClicked
            % Clear axes
            cla(silhView)
            % Plot image to axes
            fname = handles.fileList(handles.currentImage).name;
            a = imread(fname);
            a = rgb2gray(a);
            a = double(a);
            handles.a = a/max(max(a(:,:,1)));
            axes(silhView)
            imagesc(handles.a)
            colormap('gray')
            set(silhView,'XTick',[],'YTick',[]);
            % Calculate the outline based on the specified threshold settings
            [bw] = calcSilh(handles.a,handles.def_thresh,handles.aabb);
            handles.silhs(:,:,handles.currentImage) = bw;
            % Find outline and superimpose on image
            outline = bwperim(bw,8);
            [or,oc]=find(outline);
            axes(silhView)
            hold on
            plot(oc,or,'y.');
            hold off
        end
    end

%% Callback for decrementing image number
    function imNumDec_callback(~,~)
        % Update current image tracker
        val = handles.currentImage;
        if val-1 == 0
            handles.currentImage = handles.n_images;
            set(imNumEdit,'String',num2str(handles.currentImage))
        else
            handles.currentImage = val-1;
            set(imNumEdit,'String',num2str(handles.currentImage))
        end
        % Update silhouette window
        if handles.loadClicked
            % Clear axes
            cla(silhView)
            % Plot image to axes
            fname = handles.fileList(handles.currentImage).name;
            a = imread(fname);
            a = rgb2gray(a);
            a = double(a);
            handles.a = a/max(max(a(:,:,1)));
            axes(silhView)
            imagesc(handles.a)
            colormap('gray')
            set(silhView,'XTick',[],'YTick',[]);
            % Calculate the outline based on the specified threshold settings
            [bw] = calcSilh(handles.a,handles.def_thresh,handles.aabb);
            handles.silhs(:,:,handles.currentImage) = bw;
            % Find outline and superimpose on image
            outline = bwperim(bw,8);
            [or,oc]=find(outline);
            axes(silhView)
            hold on
            plot(oc,or,'y.');
            hold off
        end
    end

end