

clear all
clc
close all

addpath("...");

%% LOAD BACKGROUND IMAGE & FILTERING

% SECTION OVERVIEW: Preprocessing and Initialization.
% This section loads the initial reference image and defines the spatial smoothing filter (averaging kernel). This step is essential to minimize 
% sensor noise and ensure cleaner data for the subsequent color segmentation process.

% Data loading and Filter Initialization
B = imread('0000.bmp');                           % Load background image


% We apply an average filter (smoothing) to reduce high-frequency noise (graininess) in the images.
% This is crucial because single-pixel noise could otherwise be mistaken for a colored marker.

n = 3;                                            % Kernel size for filtering
hlow = fspecial('aver', n);                       % Create an averaging filter kernel (3x3 matrix with weight 1/9)
B_low = imfilter(B, hlow);                        % Apply the smoothing filter to the background image


%% COLOR THRESHOLD DEFINITIONS
% SECTION OVERVIEW: Color Parameter Definition.
% This section establishes the target RGB values for the foot markers and defines the specific tolerance ranges. 
% These parameters constitute the core criteriafor the segmentation algorithm, balancing precision with flexibility to handle environmental
% variations like lighting, shadows, and motion blur.

% The values below represent the "ideal" RGB color of the socks on the feet:
% - Thr (Red Marker): High Red component (230), lower Green/Blue.
% - Thb (Blue Marker): High Blue component (170), moderate Green, low Red.

% METHOD OF SELECTION: These specific values were determined empirically through a trial-and-error process.
% Multiple values were tested iteratively, adjusting the parameters until the combination that provided the most accurate and stable 
% segmentation result was found.

Thr = [230 120 150];                              % Ideal RGB THRESHOLD for Right Foot (Red)
Thb = [40 90 170];                                % Ideal RGB THRESHOLD for Left Foot (blue)

% Color in photos is never constant due to: 1. Lighting changes (shadows moving across the floor); 
% 2. Sensor noise; 3. Motion blur (smearing colors).

% Therefore, we cannot look for an exact RGB match. We needed a range. Higher tolerance = More robust to lighting changes, 
% but risk of false positives (detecting floor as foot). Lower tolerance = More precise, but risk of losing the foot if it moves into a shadow.

tolR_Thr = 30;                                    % +/- 30 variance allowed for Red channel (Right Foot).
tolG_Thr = 35;                                    % +/- 35 variance allowed for Green channel (Right Foot).
tolB_Thr = 40;                                    % +/- 40 variance allowed for Blue channel (Right Foot).

tolR_Thb = 30;                                    % +/- 30 variance allowed for Red channel (Left Foot).
tolG_Thb = 30;                                    % +/- 30 variance allowed for Green channel (Left Foot).
tolB_Thb = 50;                                    % +/- 50 variance allowed for Blue channel (Left Foot).


%% MAIN PROCESSING LOOP
% SECTION OVERVIEW: Frame-by-Frame Analysis.
% This is the core computational block of the script. It iterates through the photos sequence to extract kinematic data. 
% For each frame, the algorithm performs:
% 1. Image Preprocessing (Filtering & ROI masking) to isolate the floor area and reduce noise.
% 2. Color Segmentation to classify pixels as "Right Foot" or "Left Foot" based on the RGB thresholds defined previously.
% 3. Centroid Extraction to convert the detected pixel clusters into specific (X,Y) coordinates, effectively creating a 
% trajectory of movement over time.

first_frame = 28;
last_frame = 64;

for k = first_frame:last_frame
    
    I = imread(['00' num2str(k) '.bmp']);

    % Initialize binary masks. These will store '1' where a foot is detected and '0' elsewhere.
    FootRight = zeros(size(I,1), size(I,2));
    FootLeft = zeros(size(I,1), size(I,2));

    % Apply the same smoothing filter to the current frame to match the noise profile
    % of the thresholding logic.
    n = 3;                                                      % Kernel size
    hlow = fspecial('aver', n);                                 % Create an averaging filter(3x3 matrix with weight 1/9)
    I_low = imfilter(I, hlow);                                  % Apply the smoothing filter to the image
    
    % (ROI) - OPTIMIZATION; JUSTIFICATION: Processing the whole image is computationally expensive and risky.
    % The upper part of the image contains the whole body, wall, or other distractions that might have colors similar to 
    % the feet markers.By setting the top 800 rows to black (0), we force the algorithm to ignore them, effectively creating 
    % a "mask" that isolates the floor area.
    I_low(1:800, :, :) = 0;
    
    % COLOR SEGMENTATION LOGIC: We iterate through every pixel to check if it falls inside our defined "color ranges".
    % A pixel is accepted ONLY if all three channels (R, G, B) are within the specific tolerances.
    for i=1:size(I_low,1)
        for j=1:size(I_low,2)
            pix = double(([(I_low(i,j,1)) (I_low(i,j,2)) (I_low(i,j,3))]));
            
            % Check RF (Red socks); Logic: Is the current pixel's Red value close enough to our target Red? 
            % AND is the Green close to target Green? AND Blue to target Blue?
            if (pix(1)>=Thr(1)-tolR_Thr && pix(1)<=Thr(1)+tolR_Thr) &&...
               (pix(2)>=Thr(2)-tolG_Thr && pix(2)<=Thr(2)+tolG_Thr) &&...
               (pix(3)>=Thr(3)-tolB_Thr && pix(3)<=Thr(3)+tolB_Thr)
         
                FootRight(i,j) = 1;
            end
            
            % Check LF (Blue socks); the same logic of above but for the left foot.
            if (pix(1)>=Thb(1)-tolR_Thb && pix(1)<=Thb(1)+tolR_Thb) &&...
               (pix(2)>=Thb(2)-tolG_Thb && pix(2)<=Thb(2)+tolG_Thb) &&...
               (pix(3)>=Thb(3)-tolB_Thb && pix(3)<=Thb(3)+tolB_Thb)

                FootLeft(i,j) = 1;
            end           
        end
    end


% % PLEASE UNCOMMENT AND RUN AGAIN THE CODE, IF YOU WANT TO SHOW THE FRAMES WITH COLORED FEET. 
% % NOTE: Just run the code selecting ONLY the raws till the 132th one, since the "real" cycle end comes after this section.

% maskRGB = zeros(size(I), 'uint8');                                  
% 
% % LF in red
% maskRGB(:,:,1) = uint8(FootLeft)*255;                               
% 
% % RF in blue
% maskRGB(:,:,3) = uint8(FootRight)*255;                              
% 
% imshow(maskRGB), title('Blue LF, RED RF')
% % figure(1), imshow(FootLeft); figure(2), imshow(FootRight);
% % drawnow;




% Centroid Extraction: Converting the binary blob (cluster of white pixels) into a single (X,Y) point.
% The centroid represents the geometric center of the detected marker.

    s_right = regionprops(FootRight, 'Centroid');
    s_left = regionprops(FootLeft, 'Centroid');
   

   % VISUALIZATION/DEBUGGING BLOCK
   % % PLEASE UNCOMMENT the following section if you want to visually verify the segmentation and centroid tracking frame-by-frame during 
   % % the loop execution. This creates a real-time animation of what the algorithm "sees".
   % Combine the two binary masks (Right and Left) into a single image
   % Using the logical OR operator (|): if a pixel is 1 in either mask, it becomes 1 here.

   %   FootBoth = FootRight | FootLeft; 
   % % Display the combined binary mask
   %  figure(1), imshow(FootBoth), title(['Binary Segmentation with Centroids - Frame ' num2str(k)]);
   %  hold on; 
   % % Plot Right Foot Centroid (Red Cross)
   % % We check "~isempty" to ensure a centroid was actually found before trying to plot it.
   %  if ~isempty(s_right)
   %      plot(s_right.Centroid(1), s_right.Centroid(2), 'r+', 'MarkerSize', 10, 'LineWidth', 2);
   %  end
   % % Plot Left Foot Centroid (Blue Cross)
   %  if ~isempty(s_left)
   %      plot(s_left.Centroid(1), s_left.Centroid(2), 'b+', 'MarkerSize', 10, 'LineWidth', 2);
   %  end
   %  hold off;
   % % Slight pause (0.2 seconds) to allow the human eye to register the frame, before the loop moves to the next iteration.
   %  pause(0.2)

    % Storing the data. We use vertical concatenation cat(1, ...) because
    % regionprops returns a struct, and we need a matrix for plotting later.
    CR(k-first_frame+1,:) = cat(1, s_right.Centroid);
    CL(k-first_frame+1,:) = cat(1, s_left.Centroid);

end


%% KINEMATIC ANALYSIS: CALIBRATION & GAIT EVENT DETECTION

% SECTION OVERVIEW: From pixels to physical events.
% This section bridges the gap between raw image coordinates and physical gait parameters.
% 1. CALIBRATION: It establishes a conversion factor to translate pixel distances into real-world meters.
% 2. SPATIAL ANALYSIS: It computes the horizontal separation between the feet over time.
% 3. EVENT IDENTIFICATION: It uses signal processing (peak detection) to identify specific gait events.

% The logic is based on the biomechanical principle that the horizontal distance between feet is maximized at the moment of 'Heel Strike'.

% MANUAL CALIBRATION (PRE-CALCULATED)
% The following lines are commented out because they were performed only once to derive the conversion factor.
% PROCEDURE: 
% 1. The background image ('0000.bmp') contains two specific reference markers on the floor that are known to be exactly 1 METER apart.
% 2. Using 'ginput(2)', we manually clicked on these two points to measure the distance in pixels.
% 3. The result (approx. 525 pixels) is now hardcoded below to avoid repeating the manual selection process every time the script runs.

% B = imread('0000.bmp');                                                 % Background image
% figure, imshow(B)
% [x,y] = ginput(2);

% distancePixel = abs(x(2)-x(1));
distancePixel = 525.000;
% Factor = 1/distancePixel;                                               % Conversion meter/pixel = 0.0019
Factor = 0.0019;

% GAIT EVENT DETECTION STRATEGY: We use the horizontal distance between feet to identify gait events.
% JUSTIFICATION: In a 2D lateral view, the distance between feet is at its maximum when the leading foot strikes the ground (Heel Strike) 
% and the trailing foot pushes off. Therefore, the 'Peaks' in this distance signal correspond to the steps.
distance_Feet = abs(CR(:, 1)-CL(:, 1));                                   
% The distance_Feet contains values expressed in pixel.


% Finding the peaks (maximum separation).
[pks, locs] = findpeaks(distance_Feet);                                   
frames = first_frame:last_frame;

% 1st Peak -> Left Heel Strike (Start of cycle)(we can see in the first frame that the subject starts walking with her left leg).
% 2nd Peak -> Right Heel Strike (Mid-cycle step).
% 3rd Peak -> Left Heel Strike (End of cycle).
LContact = locs([1 3]);
RContact = locs(2);

%% GRAPH OF THE X(:, 1)COORDINATES OF THE CENTROIDS OF THE FEET
% This plot visualizes the horizontal trajectory (X-coordinate) of both feet over time.

figure(1),
plot(frames, CR(:,1), 'r', 'LineWidth', 1); hold on;
plot(frames, CL(:,1), 'b', 'LineWidth', 1);

% Show the contacts frame on the graph
xline(LContact(1) + first_frame - 1, 'r--', 'LineWidth', 1.5, 'Label', 'Initial LContact');
xline(RContact + first_frame - 1, 'g--', 'LineWidth', 1.5, 'Label', 'Contralateral RContact');
xline(LContact(2) + first_frame - 1, 'r--', 'LineWidth', 1.5, 'Label', 'Final LContact');

xlabel('Frame'), ylabel('Coordinate X [pixel]');
title('X Position of the Centroids of the Feet'), legend('Right Foot', 'Left Foot'); 
grid on, hold off;

% Key observations from the graph:

% 1. STANCE PHASE (Plateaus): The regions where the signal appears horizontal (flat) correspond to the STANCE phase. 
% During these intervals, the foot is planted firmly on the ground (pixel coordinate doesn't change) supporting the body, 
% while the contralateral leg is in the swing phase and advancing forward.

% 2. DIRECTION OF MOVEMENT: The X-coordinate values decrease as the frame number increases. This indicates the subject is walking 
% from Right to Left. Since the standard image coordinate system origin (0,0) is in the top-left corner, moving left results in a 
% reduction of the X value.

% 3. CROSSOVER POINT: The point where the Red and Blue lines cross indicates the moment the swinging leg physically passes 
% parallel to the stationary stance leg.

% 4. CYCLE INITIATION: It is observed that the analyzed gait cycle starts with the Left Foot. This is deduced from the first vertical 
% marker ('Initial LContact'), which identifies the moment the left foot ends its swing and strikes the ground, initiating the first stance
% plateau.

%% GRAPH OF HORIZONTAL FOOT DISTANCE
% This plot illustrates the absolute horizontal separation (distance) between the two feet over time.
% Key observations from the graph:

figure(2),
plot(frames, distance_Feet, 'k'); hold on;
plot(frames(locs), distance_Feet(locs), 'go', 'MarkerFaceColor', 'g');

% Evidenzia frame di contatto sulla distanza
xline(LContact(1) + first_frame - 1, 'r--', 'LineWidth', 1.5, 'Label', 'Initial LContact');
xline(RContact + first_frame - 1, 'g--', 'LineWidth', 1.5, 'Label', 'Contralateral RContact');
xline(LContact(2) + first_frame - 1, 'r--', 'LineWidth', 1.5, 'Label', 'Final LContact');

xlabel('Frame'), ylabel('X distance between feet [pixel]');
title('Horizontal distance between feet'), grid on;
hold off;


% 1. PEAKS (Maxima - Green Dots): The local maxima represent the moments of maximum extension
%    between the feet. Physically, these correspond to the "Initial Contact" or "Heel Strike" events.
%    At these points, the leading foot has just touched the ground, and the trailing foot is 
%    furthest behind, marking the beginning of the "Double Support" phase.

% 2. VALLEYS (Minima near Zero): The points where the curve drops to near zero (e.g., around frames 42 and 55)
%    correspond to the "Mid-Swing" phase. At this specific moment, the swinging leg passes 
%    directly alongside the stationary stance leg. Since they are horizontally aligned, 
%    the X-distance between them becomes zero.

% 3. GAIT CYCLE DEFINITION: The graph captures one full stride cycle defined by three events:
%    - Peak 1 (Left Contact): Start of the cycle.
%    - Peak 2 (Right Contact): Half-step (contralateral foot strike).
%    - Peak 3 (Left Contact): Completion of the stride.

% 4. SHAPE JUSTIFICATION: The signal looks like a rectified sine wave (always positive) 
%    because the code uses the absolute value function: abs(Right - Left).


%% PARAMETER CALCULATION
% SECTION OVERVIEW: Computing clinical gait parameters.
% This final calculation block translates the identified events into standard kinematic metrics:
% 1. STRIDE LENGTH: The distance covered between two consecutive heel strikes of the SAME foot (e.g., Left -> Left).
% 2. STEP LENGTH: The distance between the heel strike of one foot and the subsequent heel strike of the OPPOSITE foot (e.g., Left -> Right).
% 3. GAIT SPEED: Calculated as the Stride Length divided by the time elapsed (Stride Duration).
% All spatial values are converted from pixels to meters using the calibration 'Factor'.

% Stride Length: Distance between two consecutive contacts of the SAME foot (Left to Left).
Stride_pixel = abs(CL(LContact(1),1)-CL(LContact(2),1));
% Step Length: Distance between contact of one foot and the subsequent contact of the OTHER foot.
Step_pixel_right = abs(CL(LContact(1),1) - CR(RContact(1),1));     
Step_pixel_left  = abs(CL(LContact(2),1) - CR(RContact(1),1));    
% Store Step pixels in an array
Step_pixel = [Step_pixel_right, Step_pixel_left];
% Conversion to Meters
Stride_length = Stride_pixel*Factor;                        % Stride length in meters
Step_length_right = Step_pixel_right * Factor;              % Right step length in meters
Step_length_left  = Step_pixel_left  * Factor;              % Left step length in meters

Step_length = [Step_length_right, Step_length_left]; 

% Gait Speed Calculation
frame_rate = 30;

% Time elapsed during one stride
time = abs((LContact(2)-LContact(1)))/frame_rate;

% Speed = Distance/Time
gait_speed = Stride_length/time;


%% DATA SAVING

% Save raw variables to .mat file,
save('kinematic_parameters.mat', 'Step_length', 'Stride_length', 'gait_speed');

% Create a summary table and save it,
T = table(Factor, Stride_length, Step_length_right, Step_length_left, gait_speed, ...
    'VariableNames', {'Conversion_Factor_m_per_pixel', 'Stride_Length_m', ...
                      'Step_Length_Right_m', 'Step_Length_Left_m', 'Gait_Speed_m_per_s'});

save('tabella_parametri.mat', 'T');