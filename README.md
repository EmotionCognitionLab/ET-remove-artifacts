# ET Remove Artifacts

This tool is designed to help preprocess pupil signal from any eye-tracker (ET). This tool includes an automatic blink removal algorithm and a manual plot editor.

## Overview
<img src="/docs/overview.png" alt="overview" width="800"/>

The main feature of this program is to linearly interpolate over artifacts, as determined by detecting significant changes in the pupil velocity (top plot). The endpoints of these significant changes are marked with a pink dot (onset) and red dot (offset). These endpoints are mapped onto the raw pupil (gray plot in the bottom panel, only the blink events are not obscured). The program linearly interpolates across these endpoints and generates the "cleaned" pupil timeseries (green plot).

Other features of this program are described below (WIP).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Installation](#installation)
- [Pupil Preprocessing - Overview](#pupil-preprocessing---getting-started)
  - [Formatting the Input Data Structure](#formatting-the-input-data-structure)
  - [Loading Data](#loading-data)
  - [Interacting with the GUI](#interacting-with-the-gui)
  - [Removing Blinks and Artifacts (Automated)](#removing-blinks-and-artifacts-automated)
    - [General Processing](#general-processing)
    - [Detect Blinks](#detect-blinks)
    - [Detect Invalid Samples](#detect-invalid-samples)
    - [Interpolation Options](#interpolation-options)
  - [Removing Blinks and Artifacts (Manual)](#removing-blinks-and-artifacts-manual)
  - [Understanding the Data Structure Fields](#understanding-the-data-structure-fields)
  - [Using the Manual Plot Editor](#using-the-manual-plot-editor)
    - [When do I replace data with NaNs rather than interpolate?](#when-do-i-replace-data-with-nans-rather-than-interpolate)
  - [Don't Forget to Save Your Work!](#dont-forget-to-save-your-work)
- [How Does The Blink Removal Algorithm Work?](#how-does-the-blink-removal-algorithm-work)
- [Disclaimer](#disclaimer)
- [Author](#author)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Installation
Two installation options:

### Standalone Program
For the standalone desktop version of this app, visit the [latest release page](https://github.com/EmotionCognitionLab/ET-remove-artifacts/releases) and download the installer file that matches your operating system. Launch the installer on your local drive and follow the instructions to complete installation.

### Source Code
Dependencies:
* Matlab (tested on 2019a and later)
* Signal Processing Toolbox
* Statistics and Machine Learning Toolbox

You can download the source code if you want to use the algorithm in your own script or if you want to run the app directly through Matlab. Simply clone or download this repository, making sure that the .m and .mlapp files are located in the same directory.

The project is written and tested on Matlab 2019a. The .mlapp file might not work with older Matlab versions due to use of uicomponents that were introduced in later Matlab versions. 

The repository also includes example .mat files that demonstrates how the input data structure should be formatted to work with ET-remove-artifacts.

## Pupil Preprocessing - Overview

![Preprocessing Pipeline](/docs/preprocessing_pipeline.svg?raw=true)

Raw pupil data from any eye-tracking system can be preprocessed using the ET-Remove-Artifacts application. First, the raw pupil timeseries needs to be read from your eye-tracking system's data file output and stored in a Matlab data structure. The format for the data structure is described in the next section.

Once the raw pupil data is formatted in a data structure, you can load the data into the ET-Remove-Artifacts application. This app includes an algorithm that detects and linearly interpolates over blinks and other artifacts. For atypical artifacts that remain undetected or improperly treated by the algorithm, the manual plot editor can be used to either fix interpolations or
impute sections of the pupil signal with missing data indicators (NaNs).

### Formatting the Input Data Structure

To use the ET-Remove-Artifacts app, your raw pupil data needs to be stored in a .mat file that contains a Matlab data structure with the variable name `S`. The data structure `S` must contain a field `data` with several required and optional sub-fields. The data structure may contain pupil data from multiple sessions, where each row contains data from a different session.

* **data (required)**: the raw pupil data
* **SubjectNumber (recommended)**: optional subject/session labels
* **filter_config (optional)**: optional field used if you want to configure algorithm settings different from the default

<img src="/docs/data_structure_1.png" alt="Input Data Structure" width="730">

The `data` field contains the following sub-fields:

* **sample (required)**: the raw pupil values stored as a Nx1 numerical array
* **smp_timestamp (required)**: the sample timestamps stored as a Nx1 numerical array
* **valid (optional)**: the valid/invalid sample tag provided by some eye-trackers stored as a Nx1 logical array (1 = valid, 0 = invalid)
* **message (optional)**: any task event label relevant to the session
* **msg_timestamp (optional)**: the timestamps corresponding to the event labels in "messages"

<img src="/docs/data_structure_2.png" alt="Data Structure data sub-field" width="700">

After creating your data structure, save it as a .mat file (e.g., `save('name_of_file.mat','S')`).

For an example script that creates the data structure `S` from an eye-tracker's raw data file, take a look at the ET_ReadFile.m function and ReadRawData_Script.m in the RawData2Structure directory (example data from an SMI eye-tracker).

**Important Notes**: The `smp_timestamp` values need to be in units of seconds. The arrays in the `sample`, `smp_timestamp`, and `valid` sub-fields need to be the same size.
The `valid` sub-field should be an array of 1's and 0's, where 1's indicate the sample is valid. Some eye-trackers record *invalid* samples as 1's, so make sure to invert these in that case.

### Loading Data

To run as a standalone desktop app, simply launch the app. Alternatively, you can run ET_RemoveArtifacts_App.mlapp from the Matlab command window if you have a new enough version of Matlab. To load the data, go to File -> Load data structure (see below).
If the data has not yet been processed by ET-Remove-Artifacts, the program automatically applies the blink removal algorithm on the signal using default settings.
If the data has previously been processed by ET-Remove-Artifacts (i.e., fields created by ET-Remove-Artifacts exist and are populated), the program will not apply blink removal and will simply display the existing outputs stored in the data structure.

<img src="/docs/load_data.gif" alt="Load Data" width="1000">

### Using the Artifact Removal Algorithm (With Default Settings)

When you load in your data for the first time, the program will automatically apply the artifact removal algorithm with the default settings. 

### Interacting with the GUI

The output data (red) is displayed in the "Pupil Plot" axes and is overlayed on the original pupil data (green). You can toggle the buttons in the "Display Plots" panel to view and hide the plots and blink onset/offset points.
To interact with the plot, hover over the axes and plot tools (Zoom-in, Zoom-out, Pan) will appear on top right of the axes.
Click "Back" and "Next" to navigate through the other pupil datasets stored in your data structure. The "Index" box displays the index of your data structure that is currently being displayed.

### Removing Blinks and Artifacts (Automated)

This algorithm contains two possible methods of detecting artifacts that can be used either separately or together. We will go through each panel of the algorithm options here:

#### General Preprocessing

These should be adjusted before the options in the other panels.

* Resampling Rate: typically, set this as the sampling rate of your eye-tracker
* Resampling Multiplier: the multiplier affects the temporary sampling rate of the data passed into the algorithm.
The program resamples the data to the Resampling Rate*Multiplier and runs the algorithm on the temporarily resampled data. The data will then be resampled back to the original Resampling Rate.
For eye-trackers with a very high sampling rate (e.g., > 500 Hz), downsampling your data for the algorithm would help speed up computing time. In general, downsampling to about 200 Hz would be a good amount.
For example, if your Resampling Rate is set at 1000 Hz, you can set your Resampling Multiplier is 0.2 to get a temporary sampling rate of 200 Hz when running the algorithm.

#### Detect Blinks

Select this panel to detect blinks in the pupil signal.

* Filter Order: Must be a even number. Larger values create a "smoother" velocity plot, but may suppress the blink velocity patterns if it is too large.
* Passband Frequency (Hz): Filter allows frequencies less than this value to pass.
* Stopband Frequency (Hz): Filter does not allow frequencies greater than this value to pass.
* Peak Threshold Factor: Thresholding of a peak's amplitude in standard deviations above the mean velocity. Peaks whose amplitudes exceed this threshold are classified as an artifact peak.
* Trough Threshold Factor: Thresholding of a troughs's amplitude in standard deviations below the mean velocity. Troughs whose amplitudes exceed this threshold are classified as an artifact trough. A "blink" is characterized as an artifact trough followed soon after by an artifact peak.
* Velocity Threshold (+): Thresholding to find the point along the artifact peaks used to identify blink offsets. Smaller positive thresholds delays the blink offset, increasing the tail end of the interpolated region (and vice versa).
* Velocity Threshold (-): Thresholding to find the point along the artifact troughs used to identify blink onsets. Smaller positive thresholds makes the blink onset occur earlier, increasing the front end of the interpolated region (and vice versa).

(WIP - Figure of a blink profile to describe the thresholds)

### More Info
Unfortunately, the rest of this documentation is a bit outdated. I will get to it eventually...

For an additional reference, please see this excellent write-up documenting the entire preprocessing procedure from Isaac Menchaca: https://isaacmenchaca.github.io/2020/04/12/PupillometryPreprocessing.html


#### Detect Invalid Samples

#### Interpolation Options

### Removing Blinks and Artifacts (Manual)

### Understanding the Output Data structure


<img src="/docs/data_structure_3.png" alt="Output Data Structure" width="1000">

* Hann Window Points: this is the length (number of points) in the Hann window applied to your pupil data before generating the velocity plot. If your pupil signal is particularly noisy, you may increase this value to get a smoother velocity plot; if the magnitude of the blink signatures in your velocity plot (i.e., the sudden dip and peak) is too small, consider decreasing this value.

* Precision: successive blinks may be grouped together. Precision refers to the duration between the offset of one blink and the onset of the next blink that would group the two blinks as one. I recommend leaving this at 0.

For most cases, set your resampling rate equal to the sampling rate of your eye-tracker. The setting that I change most frequently is the *Hann Window Points*. Pupil signals with relatively large non-blink fluctuations will need a larger Hann window to generate a smoother velocity plot. I usually start with a lower value and increase the value until I see that increasing the value no longer improves the reconstructed plot meaningfully (this is subjective). I often also decrease the Velocity Thresholds (+ and -), which creates a slightly larger interpolation region. One important rule of thumb is that, for a given study run on the same eye-tracker, try to make your settings approximately similar. For instance, if you load in the Example_Data_Output.mat into the GUI, you'll notice how the Hann Window Points values fall in the 30-40 point range (on data from another one of my eye-trackers, I set this parameter between 10 and 20).

Let's take a look at an example! Load *Example_Data_Input.mat* into your GUI. This is the reconstructed plot looks like using the default algorithm parameters:

![GUI Input Data](/docs/input_parameters_gui.PNG?raw=true)


Load *Example_Data_Output.mat* into your GUI. This is the reconstructed plot (looks much better qualitatively) after changing the algorithm parameters:

![GUI Output Data](/docs/output_parameters_gui.PNG?raw=true)


Notice that in the above example, the only paramter I changed was the Hann Window Points. In this case, this was all that was needed to get a qualitatively better-looking reconstructed plot. However, there are still some blemishes in the signal, which we'll handle manually in the Plot Editor (covered in next section).

You may want to change the default settings of the algorithm parameters; for example, if you're using an eye-tracker with a different sampling rate. To change the default settings, open the ET_RemoveArtifacts_Auto.m file and under the unpack arguments section, change the current default value to your desired default value.

### Using the Manual Plot Editor

The manual plot editor is designed to *complement* the blink removal algorithm. At this stage of preprocessing, best practice is to dissociate the eye-tracking data from subject info and behavioral data.

Even though the blink removal algorithm adequately removes most of the blink events, there may be unusual artifacts that remain undetected by the algorithm. Some pupil data may have periods of "messy signal" (e.g., head movement + eye closing), and the algorithm may do a poor job at interpolating across these artifacts. The plot editor allows you to remove undetected artifacts or redo interpolation.

Once you are satisfied with the output of the blink removal algorithm, press the Manually Edit Plot button to launch the Plot Editor. The Axes Control panel allows you to pan through your plot as well as change the scale of the plot viewer. The Plot Editor Tools panel consists of the tools you'll need to edit your plot.

To edit your plot, you'll select the Start Point and End Point of the region you want to reconstruct. There are 3 functions you can apply to this region:
1. Interpolate - linearly interpolates over the select region.
2. Re-populate - replaces the selected region with original (non-reconstructed) data.
3. NaN Data - replaces the selected region with NaNs.

Here's an example of how you would use these tools:

![Plot Editor](/docs/weird_artifacts_plot_editor.PNG?raw=true)

![Plot Editor](/docs/repopulate_plot_editor.PNG?raw=true)

![Plot Editor](/docs/interpolate_plot_editor.PNG?raw=true)


Here's a different example:

![Plot Editor](/docs/messy_signal_plot_editor.PNG?raw=true)


To make this editing process more convenient, the plot editing tools are bound to keyboard hotkeys:

* WASD: arrow keys to navigate plot (AD: pans horizontally; SW: pans vertically)
* Q: select start point
* E: select end point
* Z: Interpolate
* X: Re-populate
* C: NaN Data

Some of the common cases that you would come across when editing your plots:
* An artifact in your signal that is untreated by the algorithm - select endpoints around the artifact and interpolate.
* An artifact in your signal is treated by the algorithm, but poorly done - select endpoints around the algorithm's interpolated region and re-populate the data. Then reselect the endpoints to better capture the artifact and interpolate over the reselected endpoints.
* An artifact or series of artifacts that is greater than 2-seconds in duration - select endpoints that cover this region of "messy" signal and replace with NaNs.

Load Example_Data_Final.mat to see what the final cleaned pupil data looks like after going through the entire algorithm + edit process.

#### When do I replace data with NaNs rather than interpolate?
Here, I replace that messy regions that are longer than 2-seconds with NaNs rather than interpolate. Later on in my analysis, I'll set criteria for trial exclusions based on the NaNs in the data. An example of this criteria may be: if the missing data occurs during a critical period of interest, exclude the trial. Or, if more than 50% of the pupil data in the trial is NaNs, exclude the trial.

Ultimately, defining the cut-off between interpolating and replacing with NaNs depends on your study design. Are your stimuli events long or short? What is the typical duration of the pupillary response you're interested in? The shorter the duration, the more stringent you're criteria for replacing data with NaNs. Typically, if I am unsure of whether to replace with NaNs or interpolate, I err on the side of replacing with NaNs.

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

* **Ringo Huang** - ringohhuang ***at*** g ***dot*** ucla ***dot*** edu

Feel free to reach out to me with questions regarding this tool or pupil preprocessing. Good luck!

:alien::telephone_receiver::house_with_garden:
