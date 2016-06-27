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
| number of displayed channels        | Ctrl + d                                                       |
+-------------------------------------+----------------------------------------------------------------+
| change epoch length                 | Ctrl + e                                                       |
+-------------------------------------+----------------------------------------------------------------+
| toggle components/channels          | Ctrl + t                                                       |
+-------------------------------------+----------------------------------------------------------------+
| set filter parameters               | Ctrl + f                                                       |
+-------------------------------------+----------------------------------------------------------------+
| move to next epoch                  | Arrow right                                                    |
+-------------------------------------+----------------------------------------------------------------+
| move to previous epoch              | Arrow left                                                     |
+-------------------------------------+----------------------------------------------------------------+
| move right (not a full epoch)       | Ctrl+Arrow right                                               |
+-------------------------------------+----------------------------------------------------------------+
| move left (not a full epoch)        | Ctrl+Arrow left                                                |
+-------------------------------------+----------------------------------------------------------------+
| move down to next channel section   | Page up                                                        |
+-------------------------------------+----------------------------------------------------------------+
| move up to previous channel section | Page down                                                      | 
+-------------------------------------+----------------------------------------------------------------+
| set event marker                    | right mouse click on the spot where you want to set the event  |
+-------------------------------------+----------------------------------------------------------------+
| delete event marker                 | right mouse click on the event marker                          |
+-------------------------------------+----------------------------------------------------------------+


View
''''
+-------------------------------------+----------------------------------------------------------------+
| Usage                               | Shortcut                                                       |
+=====================================+================================================================+
| enlarge channels                    | Arrow up                                                       |
+-------------------------------------+----------------------------------------------------------------+
| decrease channels                   | Arrow down                                                     |
+-------------------------------------+----------------------------------------------------------------+
| hide/show dotted vertical grid      | g                                                              |
+-------------------------------------+----------------------------------------------------------------+
| hide/show dotted horizontal grid    | h                                                              |
+-------------------------------------+----------------------------------------------------------------+
| set vertical scale spacing          | Ctrl + g                                                       |
+-------------------------------------+----------------------------------------------------------------+
| set horizontal grid spacing         | Ctrl + h                                                       |
+-------------------------------------+----------------------------------------------------------------+
| hide channels                       | click on channel number                                        |
+-------------------------------------+----------------------------------------------------------------+
| toggle negative up/down             | Ctrl + n                                                       |
+-------------------------------------+----------------------------------------------------------------+



Tools
'''''
+-------------------------------------+----------------------------------------------------------------+
| Usage                               | Shortcut                                                       |
+=====================================+================================================================+
| load eeg                            | Ctrl + l                                                       |
+-------------------------------------+----------------------------------------------------------------+
| save eeg                            | Ctrl + s                                                       |    
+-------------------------------------+----------------------------------------------------------------+
| export hidden channels              | Ctrl + x                                                       |
+-------------------------------------+----------------------------------------------------------------+
| export marked trails                | Ctrl + t                                                       |
+-------------------------------------+----------------------------------------------------------------+

How to use the Functions
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


Troubleshooting
^^^^^^^^^^^^^^^
Comments and suggestions are more than welcome, just create an issue in github with the specific question/suggestion


