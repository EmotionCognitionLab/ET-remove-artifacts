# ET Remove Artifacts

This tool is designed to help preprocess pupil signal from any eye-tracker (ET). This tool includes an automatic blink removal algorithm and a manual plot editor.

The idea behind creating this tool is to help researchers get started with pupillometry analyses. Hopefully, you'll find the GUI useful in minimizing the amount of programming necessary to preprocess pupil data.

## Prerequisites

Download the .m files in this repository to your local drive, making sure that they are located in the same directory.

The project is written and tested on Matlab 2017a/b. Should also work with earlier versions of Matlab (but no guarantees).

I recommend using Windows for complete functionality. I have tested the GUI on a Mac, but noticed some minor issues (e.g., cosmetic stuff and hotkey functionality in the plot editor).

## How To Preprocess Your Pupil Data

It's important to point out that this program is only one step in your entire preprocessing pipeline for your pupil data. Therefore, I'll use this section to describe how I usually preprocess my pupil data and how the ET Remove Artifacts GUI fits in to the overall pipeline.

I recommend using Matlab for crunching your pupil data so that this Matlab-based GUI more integrates fluidly in your pipeline; however, it is possible to use another language for the rest of your pipeline as long as your data is converted to the proper Matlab data structure for the GUI (more on this in the next section). 

Here is an example of my typical pupil preprocessing pipeline:

![Pipeline](/docs/preprocessing_pipeline.png?raw=true)


Step 1 is a necessary prerequisite for using this GUI, since the GUI reads a Matlab data structure in which the pupil data is stored in specific sub-fields.

## How To Use ET Remove Artifacts GUI

Given a typical pupil signal, the blink removal algorithm detects and removes most of the blink artifacts. However, atypical artifacts (e.g., due to multiple successive blinks, hardware noise, closed eyes, rapid head movement) may remain untreated by the automated algorithm. For these, use the manual plot editor to either interpolate over the user-defined period or replace with NaNs.

Hopefully, the previous section adequately explained the role of this GUI in context of the entire preprocessing pipeline. We'll now go over how to apply this tool - starting with your raw data files.

### Formatting the Data Structure

The GUI reads pupillometry data from a Matlab data structure "S". You'll store each set of pupillometry in seperate indices of this structure. Please format the data structure according to these specifications: variable name "S", field "data", sub-fields "sample" and "smp_timestamp." The pupil data will be stored as a numerical array in the "sample" sub-field, and its corresponding timestamps will be stored in the "smp_timestamp" sub-field. The timestamp values in smp_timestamp should be in units of *seconds*. For example, S(1).data.sample accesses the pupil data for the first subject and S(3).data.smp_timestamp accesses the timestamps for the third subject. After creating your data structure, save it as a .mat file using the command save('name_of_file.mat','S'). Importantly, the GUI assumes the timestamps are in units of seconds (so convert the units in this step if necessary). Load in the Example_Data_Input.mat in your Matlab workspace to view an example of this data structure.

Reading in your raw data to a Matlab data structure is the only programming step that is absolutely necessary to use the GUI. Take a look at ET_ReadFile.m and ReadRawData_Script.m in the RawData2Structure directory to understand how the example data structure was created from its raw data files.

### Getting Started

To start up the GUI, run the ET_ReconstructPlots_GUI.m file from your Matlab command window. After the GUI appears, click the "Select Data" button to load in your .mat file. 

![GUI Start Up](/docs/start_up_gui.PNG?raw=true)


### Using the Automatic Blink Removal Algorithm

Whenever a new dataset is displayed in your GUI, the program automatically applies the blink removal algorithm. The reconstructed data (blue) is displayed in the "Pupil Plot" axes and is overlayed on the original pupil data (green). You can toggle the buttons in the "Display Plots" panel to view and hide the plots and blink onset/offset points. You may use the Zoom-in, Zoom-out, and Pan tools to explore the plots in detail (don't use the other buttons in the menu bar).

Click "Back" and "Next" to scroll through the other pupil datasets stored in your data structure. The "Index" box displays the index of your data structure that is currently being displayed.

You can also tinker with the algorithm by changing the values in the algorithm parameters panel:

* Hann Window Points: this is the length (number of points) in the Hann window applied to your pupil data before generating the velocity plot. If your pupil signal is particularly noisy, you may increase this value to get a smoother velocity plot; if the magnitude of the blink signatures in your velocity plot (i.e., the sudden dip and peak) is too small, consider decreasing this value.
* Resampling Rate: typically, set this as the sampling rate of your eye-tracker
* Precision: successive blinks may be grouped together. Precision refers to the duration between the offset of one blink and the onset of the next blink that would group the two blinks as one. I recommend leaving this at 0.
* Velocity Threshold (+): thresholding of the velocity plot used to identify blink offsets. Smaller positive thresholds delays the blink offset, increasing the tail end of the interpolated region (and vice versa).
* Velocity Threshold (-): thresholding of the velocity plot used to identify blink onsets. Smaller negative thresholds advances the blink onset, extending the starting point of the interpolated region (and vice versa).

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

* **Ringo Huang** - ringohua**at**usc**dot**edu

Feel free to reach out to me with questions regarding this tool or pupil preprocessing. Good luck! 

:alien::telephone_receiver::house_with_garden: