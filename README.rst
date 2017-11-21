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
Navigation
''''''''''
+-------------------------------------+----------------------------------------------------------------+
| Usage                               | Shortcut                                                       |
+=====================================+================================================================+
| number of displayed channels        | ctrl + d                                                       |
+-------------------------------------+----------------------------------------------------------------+
| change epoch length                 | ctrl + e                                                       |
+-------------------------------------+----------------------------------------------------------------+
| toggle components/channels          | ctrl + t                                                       |
+-------------------------------------+----------------------------------------------------------------+
| set filter parameters               | ctrl + f                                                       |
+-------------------------------------+----------------------------------------------------------------+
| move to next epoch                  | arrow right                                                    |
+-------------------------------------+----------------------------------------------------------------+
| move to previous epoch              | arrow left                                                     |
+-------------------------------------+----------------------------------------------------------------+
| move right (not a full epoch)       | ctrl + arrow right                                             |
+-------------------------------------+----------------------------------------------------------------+
| move left (not a full epoch)        | ctrl + arrow left                                              |
+-------------------------------------+----------------------------------------------------------------+
| move down to next channel section   | page up                                                        |
+-------------------------------------+----------------------------------------------------------------+
| move up to previous channel section | page down                                                      | 
+-------------------------------------+----------------------------------------------------------------+
| set event marker                    | use keyboard numbers to place event at mouse position	       |
+-------------------------------------+----------------------------------------------------------------+
| set event marker alternative        | right mouse click and use context menu                         |
+-------------------------------------+----------------------------------------------------------------+
| delete event marker                 | left mouse click on the event marker                           |
+-------------------------------------+----------------------------------------------------------------+


View
''''
+-------------------------------------+----------------------------------------------------------------+
| Usage                               | Shortcut                                                       |
+=====================================+================================================================+
| increase channel scale              | arrow up                                                       |
+-------------------------------------+----------------------------------------------------------------+
| decrease channel scale              | arrow down                                                     |
+-------------------------------------+----------------------------------------------------------------+
| hide/show dotted vertical grid      | g                                                              |
+-------------------------------------+----------------------------------------------------------------+
| hide/show dotted horizontal grid    | h                                                              |
+-------------------------------------+----------------------------------------------------------------+
| set vertical scale spacing          | ctrl + g                                                       |
+-------------------------------------+----------------------------------------------------------------+
| set horizontal grid spacing         | ctrl + h                                                       |
+-------------------------------------+----------------------------------------------------------------+
| hide / mark channels                | click on channel label                                         |
+-------------------------------------+----------------------------------------------------------------+
| toggle negative up/down             | ctrl + n                                                       |
+-------------------------------------+----------------------------------------------------------------+



Tools
'''''
+-------------------------------------+----------------------------------------------------------------+
| Usage                               | Shortcut                                                       |
+=====================================+================================================================+
| load eeg                            | ctrl + l                                                       |
+-------------------------------------+----------------------------------------------------------------+
| save eeg                            | ctrl + s                                                       |    
+-------------------------------------+----------------------------------------------------------------+
| export hidden channels              | ctrl + x                                                       |
+-------------------------------------+----------------------------------------------------------------+
| export marked trials                | ctrl + t                                                       |
+-------------------------------------+----------------------------------------------------------------+

How to sleep score using the plotter
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Open the *csc_eeg_plotter(EEG)*, you will likely want to adjust the montage to match a more typical sleep scoring montage (e.g. F3-A2). 

For classic sleep scoring, change the mode in the tools menu and use the numbers on the keyboard to mark the stages (wake should be number 6, not 0).
You can mark arousal beginnings and end using the number 4 (since there is no NREM4 anymore).

For continuous sleep scoring simple place a marker at the beginning of the stage transition (keyboard number at mouse position).

If there is a long period prior to sleep that should not be considered for scoring (e.g. lights on), then simply begin scoring at a later epoch.

Once your scoring is complete, you can use the function *csc_events_to_hypnogram* to produce a table and convert into stages stored in *EEG.swa_scoring.stages*.
You should probably also save the events to file just in case (using the event menu in the plotter).

How to use the functions
^^^^^^^^^^^^^^^^^^^^^^^^
in this example we assume `EEG` is you loaded dataset:

  to open the plotter and check e.g. for artifacts and hide bad channels use the code 
   ```
   EEG = csc_eeg_plotter(EEG);
   ```
  to change the hidden channels to bad channels use
   ```
   EEG.bad_channels{1} = EEG.hidden_channels;
   ```
  to reject/delete channels with artifacts
   ```
   EEG = pop_select(EEG, 'nochannel', EEG.bad_channels{1});
   ```

if you have run e.g. ICA on your dataset and want to look/remove components

   open the plotter and also the component plot for each channel
    ```
    csc_eeg_plotter(EEG);
    EEG.good_components = csc_component_plot(EEG);
    ```
   now to remove the marked bad components and automaticaly change the local eeg variable use
    ```
    EEG = pop_subcomp( EEG , find(~EEG.good_components));
    EEG = eeg_checkset(EEG);
    ```
    you can also open the *csc_eeg_plotter* to visualise the components and also plot the channel activity as if the selected components had already been removed

Troubleshooting
^^^^^^^^^^^^^^^
Comments and suggestions are more than welcome, just create an issue in github with the specific question/suggestion


