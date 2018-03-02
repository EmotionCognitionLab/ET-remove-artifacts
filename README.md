# ET Remove Artifacts

This tool is designed to help preprocess pupil signal. The two components of this tool include an automatic blink removal algorithm and a manual plot editor.

Given a typical pupil signal, the blink removal algorithm detects and removes most of the artifacts attributed to blinks. However, atypical artifacts (e.g., multiple successive blinks, hardware noise, closed eyes, rapid head movement) may remain untreated by the automated algorithm. For artifacts that are undetected by the algorithm, use the manual plot editor to either interpolate over the user-defined period or replace with NaNs.

The idea behind creating a GUI for removing artifacts is to minimize the amount of programming needed for researchers to preprocess pupil data. Hopefully, this tool will make the data-crunching process a little less intimidating!

## Prerequisites

Download the .m files in this repository to your local drive, making sure that they are located in the same directory.

The project is written and tested on Matlab 2017a/b. Should also work with earlier versions of Matlab (but no guarantees).

I recommend using Windows for complete functionality. I have tested the GUI on a Mac, but noticed some minor issues (e.g., cosmetic stuff and hotkey functionality in the plot editor).

## How To Preprocess Your Pupil Data (For Matlab Users)

Before jumping into the GUI, it's important to point out that this program is only one step in your entire preprocessing pipeline for your pupil data. Therefore, I'll use this section to present an overview of how I usually preprocess my pupil data. This overview is mostly geared towards people new at crunching pupillometry data. For more experienced users with their own preprocessing procedure, this section isn't super relevant - however, please note the specific format of the Matlab data structure used by the GUI.

My preferred data-crunching environment is Matlab (which is why this repository is written in Matlab), but the following preprocessing steps can be replicated with any language of your choice (except step 2). I store all the pupil data from my study in a single Matlab data structure and pass that data structure along the pipeline.

Pupil Preprocessing Pipeline:
![Pipeline](/docs/preprocessing_pipeline.png?raw=true)

Step 1 is a necessary prerequisite for using this GUI, since the GUI reads a Matlab data structure in which the pupil data is stored in specific sub-fields.

## How To Use ET Remove Artifacts GUI

Hopefully, the previous section has put the purpose of this GUI in context of the entire preprocessing pipeline. This GUI should be a fairly upstream step in your pipeline (i.e., the cleaned pupil data should be your new data source for later steps).

### Formatting the Data Structure

When reading your raw data into the Matlab data structure, please format the data structure according to these specifications: variable name "S", field "data", sub-fields "sample" and "smp_timestamp." Each index of your data structure "S" corresponds to a different subject. In other words, S(1).data.sample contains the pupil data for the first subject and S(3).data.smp_timestamp contains the timestamp data for the third subject. After creating your data structure, save it as a .mat file using the command save('name_of_file.mat','S'). Importantly, the GUI assumes the timestamps are in units of seconds (so convert the units in this step if necessary).

This step is really the only programming step that is required to use the GUI for your dataset. Please load in Example_Data_Input.mat for an example of the properly formatted data structure, and see the RawData2Structure folder for an example of how to create the data structure.

### Getting Started

To start up the GUI, run the ET_ReconstructPlots_GUI.m file from your Matlab command window. After the GUI appears, click the "Load Data" button to load in your .mat file. Whenever a new pupil timecourse is loaded into the GUI, the blink removal algorithm is automatically performed using default settings. You may use the Zoom-in, Zoom-out, and Pan tools to explore the plots in detail (note that the other buttons in the menu-bar aren't applicable to the GUI). You can also toggle the buttons in the Display Plots panel to compare the original vs the reconstructed plots and visualize the onset/offset of blinks.

(screenshot here - Caption: this is what the GUI should look like after loading the data.)

### Using the Automatic Blink Removal Algorithm

If you're not satisfied with the initial output of the algorithm, you may want tinker with the options in the algorithm parameters panel. 

* Hanning Window: this is the order of the filter used to smooth the pupil plot before generating the velocity plot. If your pupil signal is particularly noisy, you may increase this value to get a smoother velocity plot; if the magnitude of the blink signatures in your velocity plot (i.e., the sudden dip and peak) is too small, consider decreasing this value.
* Resampling Rate: typically, set this as the sampling rate of your eye-tracker
* Precision: successive blinks may be grouped together. Precision refers to the duration between the offset of one blink and the onset of the next blink that would group the two blinks as one. I recommend leaving this at 0.
* Velocity Threshold (+): thresholding of the velocity plot used to identify blink offsets. Smaller positive thresholds delays the blink offset, increasing the tail end of the interpolated region (and vice versa).
* Velocity Threshold (-): thresholding of the velocity plot used to identify blink onsets. Smaller negative thresholds advances the blink onset, extending the starting point of the interpolated region (and vice versa).

(screrenshot here - Caption: )

You may want to change the default settings of the algorithm parameters; for example, if you're using an eye-tracker with a different sampling rate. To change the default settings, open the ET_RemoveArtifacts_Auto.m file and under the unpack arguments section, change the current default value to your desired default value.

### Using the Manual Plot Editor

The manual plot editor is designed to *complement* the blink removal algorithm - needless to say, do not use this tool to manipulate the data. At this stage of preprocessing, best practice is to dissociate the eye-tracking data from subject info and behavioral data.

Even though the blink removal algorithm adequately removes most of the blink events, there may be unusual artifacts that remain undetected by the algorithm. Some pupil data may have periods of "messy signal" (e.g., head movement + eye closing), and the algorithm may do a poor job at interpolating across these artifacts. The plot editor allows you to remove undetected artifacts or redo interpolation.

Once you are satisfied with the output of the blink removal algorithm, press the Manually Edit Plot button to launch the Plot Editor. The Axes Control panel allows you to pan through your plot as well as change the scale of the plot viewer. The Plot Editor Tools panel consists of the tools you'll need to edit your plot.

To edit your plot, you'll select the Start Point and End Point of the region you want to reconstruct. There are 3 functions you can apply to this region:
1. Interpolate - linearly interpolates over the select region.
2. Re-populate - replaces the selected region with original (non-reconstructed) data.
3. NaN Data - replaces the selected region with NaNs.

Some of the common cases that you would come across when editing your plots:
* An artifact in your signal that is untreated by the algorithm - select endpoints around the artifact and interpolate.
* An artifact in your signal is treated by the algorithm, but poorly done - select endpoints around the algorithm's interpolated region and re-populate the data. Then reselect the endpoints to better capture the artifact and interpolate over the reselected endpoints.
* An artifact or series of artifacts that is greater than 2-seconds in duration - select endpoints that cover this region of "messy" signal and replace with NaNs. 

My own personal rule of thumb (shouldn't be taken as fact): I typically replace that messy regions that are longer than 2-seconds with NaNs rather than interpolate. Later on in my analysis, I'll set criteria for trial exclusions based on the NaNs in the data. An example of this criteria may be: if the missing data occurs during a critical period of interest, exclude the trial. Or, if more than 50% of the pupil data in the trial is NaNs, exclude the trial.

### Don't Forget to Save Your Work!

When using this GUI, I suggest saving your output data structure under a different filename and making changes to that file. To do so: after loading in your input data structure, select the Save As button and save a copy of your data structure under a different file name. From then, whenever you restart the GUI, make sure to load in the new file and not the original input file.

## How Does The Blink Removal Algorithm Work?

The blink removal algorithm is based on the process described by Sebastiaan Mathot: www.researchgate.net/publication/236268543_A_simple_way_to_reconstruct_pupil_size_during_eye_blinks
For typical behavioral studies, the acquired pupillometry data is a slowly varying signal with occasional phasic changes in response to behavioral events. This slowly varying signal is interrupted by intermittent blink artifacts, which are characterized as a sudden decrease in pupil size followed by a sudden increase. Thus, we're able to detect blink events by looking at the velocity plot of the pupil signal. During periods of slowly changing signal, the velocity fluctuates around 0. In contrast, blink onsets are characterized by large negative velocities and blink offsets are characterized by large positive velocities. 

Steps:
   1. Resample data
   2. Generate velocity profile - first smooth the data using a hanning window
   3. Detect blink onsets/offsets by identifying intersections between velocity profile and negative/positive threshold
   4. Interpolate over blink onset/offset pairs

## Disclaimer

The tools in this repository and the preprocessing steps described above are designed with my own projects in mind. The guidelines expressed above should be taken as suggestions based on my own experiences and are *not* standardized rules for pupillometry preprocessing.

## Author

* **Ringo Huang** - ringohua@usc.edu (Feel free to reach out to me with questions regarding this tool or pupil preprocessing!)