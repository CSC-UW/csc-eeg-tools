csc-eeg-tools
=============

This set of functions is designed to be used as quick tools in matlab for eeg processing
The tools can be used on their own or by using one of the template files provided

Get the code
^^^^^^^^^^^^

To get the latest code using git, simply type:
    git clone https://github.com/CSC-UW/csc-eeg-tools.git

Installation
^^^^^^^^^^^^
1. download zip file
2. extract and save under your prefered path
3. add the path to matlab and you're ready to go

Key-Shortcuts for Plotter
^^^^^^^^^^^^^^^^^^^^^^^^^
load eeg                                - Ctrl+L
save eeg                                - Ctrl+S

change nbr of displayed channels		- Ctrl+D
change epoch length 					- Ctrl+E

toggle components/channels				- Ctrl+T

set high/low cutoff 					- Ctrl+F

enlarge channels						- Arrow up
decrease channels						- Arrow down

move right to next epoch				- Arrow right
move left to previous epoch				- Arrow left
move right (not a full epoch)			- Ctrl+Arrow right
move left (not a full epoch)			- Ctrl+Arrow left

move down to next section of channels	- Page down
move up to previous section of channels	- Page up

hide channels							- click on the channels nbr

set event 								- right mouse click on the spot where you want to set the event
delete event							- right click on the event marker

remove/add dotted 1 sec segments		- G

export hidden channels					- Ctrl+X
export marked trials					- Ctrl+T

How to use the Functions
^^^^^^^^^^^^^^^^^^^^^^^^
in this example we assume `EEG` is you loaded dataset:

  1. to open the plotter and check e.g. for artifacts and hide bad channels use the code 
  2. `EEG = csc_eeg_plotter(EEG);`
  3. to change the hidden channels to bad channels use
  4. `EEG.bad_channels{1} = EEG.hidden_channels;```
  5. to reject/delete channels with artifacts
  6. `EEG = pop_select(EEG, 'nochannel', EEG.bad_channels{1});`

if you have run e.g. ICA on your dataset and want to look/remove components

   open the plotter and also the component plot for each channel
    `csc_eeg_plotter(EEG);`
    `EEG.good_components = csc_component_plot(EEG);`
   now to remove the marked bad components and automaticaly change the local eeg variable use
    `EEG = pop_subcomp( EEG , find(~EEG.good_components));`
    `EEG = eeg_checkset(EEG);`






Troubleshooting
^^^^^^^^^^^^^^^
Comments and suggestions are more than welcome, just create an issue in github with the specific question/suggestion


