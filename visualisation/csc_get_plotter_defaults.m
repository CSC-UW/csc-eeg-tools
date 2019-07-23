function [settings] = csc_get_plotter_defaults(varargin)
% grabs the set default options for the csc_eeg_plotter before overriding
% user  for that session
% if you often change the  manually, you can change the defaults 
% within this function so they are automatically applied

%% set defaults
% NOTE: if default not specified here, see section below
defaults = struct(...
    'epoch_length', 30); % length of time displayed (seconds) and default scoring window

%% parse the input
% initialise parser
args_in = inputParser;

% data view settings
addParameter(args_in,...
    'epoch_length', defaults.epoch_length, ... % length of time displayed (seconds)
    @(x) isnumeric(x) && (x > 0));
addParameter(args_in,...
    'n_disp_chans', 12, ... % number of channels to display
    @check_int);
addParameter(args_in,...
    'negative_up', false, ... % negative values go up, as in clinical settings [true / fale]?
    @(x) islogical(x) || (x == 0) || (x == 1));

% grid settings
addParameter(args_in,...
    'plot_v_grid', true, ... % show vertical grid spacing [true / fale]?
    @(x) islogical(x) || (x == 0) || (x == 1));
addParameter(args_in,...
    'v_grid_spacing', 1, ... % spacing between vertical grid lines (seconds)
    @(x) isnumeric(x) && (x > 0));
addParameter(args_in,...
    'plot_h_grid', true, ... % % show horizontal grid spacing [true / fale]?
    @(x) islogical(x) || (x == 0) || (x == 1));
addParameter(args_in,...
    'h_grid_spacing', 75, ... % spacing between horizontal grid lines (microVolts)
    @(x) isnumeric(x) && (x > 0));

% event settings
addParameter(args_in,...
    'event_number_of_types', 6, ... % spacing between horizontal grid lines (microVolts)
    @check_int);

% sleep scoring settings
addParameter(args_in,...
    'scoring_mode', false, ... % activate sleep scoring mode [true / fale]?
    @(x) islogical(x) || (x == 0) || (x == 1));
addParameter(args_in,...
    'scoring_window', defaults.epoch_length, ... % how far window scrolls after scoring (seconds)
    @(x) isnumeric(x) && (x > 0));
addParameter(args_in,...
    'scoring_offset', 0, ... % % where (in window) to place event marker
    @(x) isnumeric(x) && (x < defaults.epoch_length));


%% check the inputs versus the defaults
parse(args_in, varargin{:});

% pass the results of the parsing to the output
settings = args_in.Results;


%% define the default options
% viewing defaults
% settings.filter_options = [0.7 40; 10 40; 0.3 10; 0.1 10]; % default filter bands

% settings.epoch_length = 30; % default viewing window
% settings.n_disp_chans = 12; % number of initial channels to display
% settings.v_grid_spacing = 1; % vertical grid default spacing (s)
% settings.h_grid_spacing = 75; % horizontal grid default spacing (uV)
% settings.plot_hgrid = 1; % plot the horizontal grid
% settings.plot_vgrid = 1; % plot the vertical grid
% settings.negative_up = false; % negative up by default (for clinicians)

% % event defaults
% settings.number_of_event_types = 6; % how many event types do you want
% settings.flag_channel_events = false; % record/show the channel label of the event
% 
% % java defaults
% settings.flag_java = true; % enable undocumented java functions to make things look prettier
% 
% % sleep scoring options
% settings.scoring_mode = false; % sleep scoring off by default
% settings.scoring_window = settings.epoch_length; % how far window scrolls
% settings.scoring_offset = 0; % where (in window) to place event marker
% 
% % ICA components options
% settings.plotICA = false; % plot components by default
% settings.component_projection = false; % viewing the difference between the data and remaining ica component projections
% 
% % define the default colorscheme to use
% settings.colorscheme = struct(...
%     'fg_col_1',     [0.9, 0.9, 0.9] , ...     
%     'fg_col_2',     [0.8, 0.8, 0.8] , ...    
%     'fg_col_3',     [0.5, 0.5, 0.5] , ...        
%     'bg_col_1',     [0.1, 0.1, 0.1] , ...
%     'bg_col_2',     [0.2, 0.2, 0.2] , ...
%     'bg_col_3',     [0.15, 0.15, 0.15] );


function result = check_int(x)
% check if input is an integer and specify custom error message
% otherwise error is "must pass the function (isreal(x) && rem(x,1)==0 && (x > 0)) which isn't very clear
if (isreal(x) && rem(x,1)==0 && (x > 0))
    result = true;
else
    result = false;
    error('Input must be a positive integer.');
end