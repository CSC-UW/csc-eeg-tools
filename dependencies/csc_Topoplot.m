function H = csc_Topoplot(data_to_plot, e_loc, varargin)
%% New Topoplot Function
%
% Usage H = csc_Topoplot(data_to_plot, e_loc, varargin)
%
% V is a single column vector of the data to be plotted (must have the length of the number of channels)
% e_loc is the EEGLAB generated structure containing all information about electrode locations
%
%
% Optional Arguments:
% See default settings below (can all be changed as optional arguments

% you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% ept_ResultViewer is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with ept_ResultViewer.  If not, see <http://www.gnu.org/licenses/>.

%% Set defaults
GridScale           = 100;          % Determines the quality of the image
HeadWidth           = 2.5;
HeadColor           = [0,0,0];
ContourWidth        = 0.5;
NumContours         = 12;

PlotContour         = 1;            % Determines whether the contour lines are drawn
PlotSurface         = 0;            % Determines whether the surface is drawn
PlotHead            = 1;            % Determines whether the head is drawn 
PlotChannels        = 1;            % Determines whether the channels are drawn
MarkedChannels      = [];           % Determines whether significant channels are plotted separately
MarkedString        = '!';
MarkedColor         = [0, 0, 0];

NewFigure           = 1;            % 0/1 - Whether to explicitly draw a new figure for the topoplot
Axes                = 0;

if isempty(data_to_plot)
    fprintf(1, 'Warning: Input data was found to be empty \n');
    return;
end

%% Process Secondary Arguments
if nargin > 2
  if ~(round(nargin/2) == nargin/2)
    error('Odd number of input arguments??')
  end
  for n = 1:2:length(varargin)
    Param = varargin{n};
    Value = varargin{n+1};
    if ~ischar(Param)
      error('Flag arguments must be strings')
    end
    Param = lower(Param);
    
    switch Param
        case 'headwidth'
            HeadWidth = Value;
        case 'numcontours'
            NumContours = Value;    
        case 'newfigure'
            NewFigure = Value;
        case 'axes'
            Axes = Value;
        case 'plotcontour'
            PlotContour = Value;
        case 'plotsurface'
            PlotSurface = Value;
        case 'plotchannels'
            PlotChannels = Value;
        case 'markedchannels'
            MarkedChannels = Value;
        case 'markedcolor'
            MarkedColor = Value;
        case 'markedstring'
            MarkedString = Value;
        case 'plothead'
            PlotHead = Value;     
        otherwise
            display (['Unknown parameter setting: ' Param])
    end
  end
end

%% Adjust Settings based on Arguments

if nansum(data_to_plot(:)) == 0 
    PlotContour = 0;
end

% if axes is specified no new figure
if Axes ~= 0
    NewFigure = 0;
end

% Overwrite number of contours if the interpolated surface is drawn
if PlotSurface == 1
    PlotContour = 0; % Overwrite contours for surface
    NumContours = 5;
end

% check that marked channels size is same as electrodes
if ~isempty(MarkedChannels)
   if length(MarkedChannels) ~= length(e_loc)
       fprintf(1, 'Warning: Marked Channels different size than number of electrodes.\n');
       MarkedChannels = [];
   end
end

% Adjust the contour lines to account for the minimum and maximum difference in values
LevelList   = linspace(min(data_to_plot(:)), max(data_to_plot(:)), NumContours);


%% Use the e_loc to project points to a 2D surface

Th = pi/180*[e_loc.theta]; % Calculate theta values from x,y,z e_loc
Rd = [e_loc.radius]; % Calculate radian values from x,y,z e_loc

x_coordinates = Rd.*cos(Th); % Calculate 2D projected X
y_coordinates = Rd.*sin(Th); % Calculate 2D projected Y

% Squeeze the coordinates into a -0.5 to 0.5 box
intrad = min(1.0,max(abs(Rd))); intrad = max(intrad,0.5); squeezefac = 0.5/intrad;

x_coordinates = x_coordinates * squeezefac; 
y_coordinates = y_coordinates * squeezefac;

%% Create the plotting mesh
XYrange = linspace(-0.5, 0.5, GridScale);
XYmesh = XYrange(ones(GridScale,1),:);

%% Create the interpolation function
x_coordinates=x_coordinates(:); y_coordinates=y_coordinates(:); data_to_plot = data_to_plot(:); % Ensure data is in column format

% Check Matlab version for interpolant...
if exist('scatteredInterpolant', 'file')
    % If its available use the newest function
    F = scatteredInterpolant(x_coordinates, y_coordinates, data_to_plot, 'natural', 'none');
else
    % Use the old function
    F = TriScatteredInterp(x_coordinates, y_coordinates, data_to_plot, 'natural');
end

% apply function 
interpolated_map = F(XYmesh', XYmesh);

%% Actual Plot

% Prepare the figure
% Check if there is a figure currently opened; otherwise open a new figure
if isempty(get(0,'children')) || NewFigure == 1
    H.Figure = figure;
    set(H.Figure,...
    'Color',            'w'                 ,...
    'Renderer',         'painters'            );

    H.CurrentAxes = axes('Position',[0 0 1 1]);
elseif Axes ~= 0
    H.CurrentAxes = Axes;
else
    H.CurrentAxes = gca;
end
% 
% Prepare the axes
set(H.CurrentAxes,...
    'XLim',             [-0.5, 0.5]         ,...
    'YLim',             [-0.5, 0.5]         ,...
    'NextPlot',         'add'               );

%% Plot the contour map
if PlotContour == 1
    [~,H.Contour] = contourf(H.CurrentAxes, XYmesh,XYmesh',interpolated_map);
    set(H.Contour,...
        'EdgeColor',        'none'              ,...
        'LineWidth',        ContourWidth        ,...
        'LineStyle',        'none'              ,...
        'LevelList',        LevelList           ,...
        'HitTest',          'off'               );
end

%% Plot the surface interpolation
if PlotSurface == 1
    unsh = (GridScale+1)/GridScale; % un-shrink the effects of 'interp' SHADING
    H.Surface = surface(XYmesh*unsh ,XYmesh'*unsh, zeros(size(interpolated_map)), interpolated_map);
    set(H.Surface,...
        'EdgeColor',        'none'              ,...
        'FaceColor',        'interp'            ,...
        'HitTest',          'off'               );
end

%% Prepare the Head, Ears, and Nose (thanks EEGLAB!)
if PlotHead == 1;
    sf = 0.333/0.5; %Scaling factor for the headsize

    % Head
    angle   = 0:1:360;
    datax   = (cos(angle*pi/180))/3;
    datay   = (sin(angle*pi/180))/3; 

    % Nose...
    base    = 0.4954;
    basex   = 0.0900;                 % nose width
    tip     = 0.5750; 
    tiphw   = 0.02;                   % nose tip half width
    tipr    = 0.005;                  % nose tip rounding

    % Ears...
    q       = .04; % ear lengthening
    EarX  = [.497-.005  .510        .518        .5299       .5419       .54         .547        .532        .510    .489-.005]; % rmax = 0.5
    EarY  = [q+.0555    q+.0775     q+.0783     q+.0746     q+.0555     -.0055      -.0932      -.1313      -.1384  -.1199];

    % Plot the head
    H.Head(1) = plot(H.CurrentAxes, datax, datay);
    H.Head(2) = plot(H.CurrentAxes,...
             [basex;tiphw;0;-tiphw;-basex]*sf,[base;tip-tipr;tip;tip-tipr;base]*sf);
    H.Head(3) = plot(H.CurrentAxes,...
                    EarX*sf,EarY*sf);% plot left ear
    H.Head(4) = plot(H.CurrentAxes,...
                    -EarX*sf,EarY*sf);   % plot right ear

    % Set the head properties
    set(H.Head,...
        'Color',            HeadColor           ,...
        'LineWidth',        HeadWidth           ,...
        'HitTest',          'off'               );
end


% Plot Channels
% ^^^^^^^^^^^^^
labels    = {e_loc.labels};
% set the label for each individually
for n = 1:size(labels,2)
    H.Channels(n) = text(y_coordinates(n),x_coordinates(n), '.', ...
        'userdata', char(labels(n)), ...
        'visible', 'off', ...
        'parent',  H.CurrentAxes);
end

% set channel parameters
set(H.Channels, ...
    'HorizontalAlignment',  'center'        ,...
    'VerticalAlignment',    'middle'        ,...
    'Color',                'k'             ,...
    'FontSize',             10              ,...
    'FontWeight',           'bold'          );

% if plot channels is enabled, make them visible
% and configure the button down function
if PlotChannels
    set(H.Channels, ...
        'visible', 'on', ...
        'buttondownfcn', ...
        ['tmpstr = get(gco, ''userdata'');' ...
        'set(gco, ''userdata'', get(gco, ''string''));' ...
        'set(gco, ''string'', tmpstr); clear tmpstr;'] );
end

% plot the marked channels
% ^^^^^^^^^^^^^^^^^^^^^^^^
if ~isempty(MarkedChannels)
    set(H.Channels(MarkedChannels), ...
        'visible', 'on', ...
        'fontSize', 15, ...
        'color', MarkedColor, ...
        'string', MarkedString);
end


% Adjustments
% ^^^^^^^^^^^
% square axes
set(H.CurrentAxes, 'PlotBoxAspectRatio', [1, 1, 1]);
% hide the axes
set(H.CurrentAxes, 'visible', 'off');

