# 🚶‍♂️ 2D Kinematic Gait Analysis via Color Segmentation

## 🎯 Project Overview
This repository contains a MATLAB-based computer vision pipeline for extracting spatiotemporal gait parameters from a 2D video sequence. By leveraging color segmentation, the script tracks specific colored markers (red and blue socks) worn on a subject's feet to analyze step and stride mechanics, calculating clinical parameters without the need for expensive motion capture systems.

## ⚙️ Methodology & Pipeline
The script processes the video sequence frame-by-frame (`0000.bmp` to `0064.bmp`) executing the following steps:
* **Image Preprocessing:** Applies a 3x3 averaging filter kernel to the background and current frames to minimize high-frequency sensor noise.
* **Region of Interest (ROI) Masking:** Sets the top 800 rows of the image to black, isolating the floor area to optimize computational efficiency and prevent false positives from the background.
* **Color Segmentation:** Isolates the Right Foot (Red) and Left Foot (Blue) by comparing pixel values against empirically defined RGB thresholds with specific tolerances to account for lighting variations.
* **Centroid Tracking:** Uses `regionprops` to compute the geometric center (X, Y coordinates) of the detected binary blobs, generating a spatial trajectory over time.
* **Event Detection:** Identifies "Heel Strike" events by analyzing the absolute horizontal distance between the feet and locating the peaks using the `findpeaks` function.
* **Calibration:** Converts pixel distances into physical spatial metrics using a pre-calibrated conversion factor of 0.0019 m/pixel.

## 📊 Extracted Kinematic Parameters
The algorithm automatically identifies the Stance, Swing, and Double Support phases to calculate the following clinical metrics:
* **Stride Length:** The physical distance between consecutive heel strikes of the same foot.
* **Step Length:** The physical distance between the heel strike of one foot and the subsequent heel strike of the opposite foot.
* **Gait Speed:** Computed by dividing the Stride Length by the elapsed time, assuming a standard camera frame rate of 30 fps (Speed = Distance / Time).

## 🚀 How to Run (Installation & Usage)
1. **Prerequisites:** Ensure you have MATLAB installed along with the **Image Processing Toolbox** and **Signal Processing Toolbox** (required for the `regionprops` and `findpeaks` functions).
2. **Setup Data:** Place the MATLAB script and the sequence of `.bmp` images (including the background `0000.bmp`) in the same directory. If the images are in a different folder, update the `addpath("...");` string at the very beginning of the code.
3. **Configure Frames:** Open the script and modify the variables `first_frame` and `last_frame` to match the exact sequence of images you want to analyze (currently set to `first_frame = 28;` and `last_frame = 64;`).
4. **Enable Visualizations (Optional):** If you want to see the algorithm segmenting the colors and tracking the centroids in real-time, uncomment the block labeled `% VISUALIZATION/DEBUGGING BLOCK` inside the main `for` loop.
5. **Execute:** Run the script. The algorithm will automatically generate the trajectory plots and save the extracted clinical metrics in `kinematic_parameters.mat` and `tabella_parametri.mat`.
