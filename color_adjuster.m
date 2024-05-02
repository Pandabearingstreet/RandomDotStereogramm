% Clear the workspace
sca;
clear;
close all;

% Shuffle the random number generator so that we get randomly positioned
% dots on each rune
rng('shuffle');

%--------------------------------------------------------------------------
%                      Set up the screen
%--------------------------------------------------------------------------

% Set the stereomode 6 for red-green anaglyph presentation. You will need
% to view the image with the red filter over the left eye and the green
% filter over the right eye. Note that with color filters you will get some
% from of cross talk normally, unless you have matched the filtered well to
% your screen, or compensated for this.
stereoMode = 6;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Setup Psychtoolbox for OpenGL 3D rendering support and initialize the
% mogl OpenGL for Matlab wrapper
InitializeMatlabOpenGL;

% Get the screen number
screenid = max(Screen('Screens'));

% Open the main window
[window, windowRect] = PsychImaging('OpenWindow', screenid, 0,...
    [], 32, 2, stereoMode);

% Show cleared start screen:
Screen('Flip', window);

% Screen size pixels
[screenXpix, screenYpix] = Screen('WindowSize', window);

% Queries the display size in mm as reported by the operating system. Note
% that there are some complexities here. See Screen DisplaySize? for
% information. So always measure your screen size directly. We just use the
% reported value for the purposes of this demo.
[widthMM, heightMM] = Screen('DisplaySize', screenid);

% Convert to CM
screenYcm = heightMM / 10;
screenXcm = widthMM / 10;

% Centimeters per pixel
pixPerCm = mean([screenYpix / screenYcm screenXpix / screenXcm]);

% Set up alpha-blending for smooth (anti-aliased) edges to our dots
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');


%--------------------------------------------------------------------------
%                      Set up the screen
%--------------------------------------------------------------------------

% Diameters and radius of each of our circles
circleDiaCm = [5 10 15];
circleDiaPix = circleDiaCm .* pixPerCm;
circleRadsPix = circleDiaPix ./ 2;

% Number of dots
numDots = 3000;

% Generate some dot coordinates
biggestRad = max(circleRadsPix);
dotPosX = (rand(1, numDots) .* 2 - 1) .* biggestRad;
dotPosY = (rand(1, numDots) .* 2 - 1) .* biggestRad;

% Filter the ones  in the biggest circle
inBig = dotPosX.^2 + dotPosY.^2 < biggestRad^2;
dotPosX = dotPosX(inBig == 1);
dotPosY = dotPosY(inBig == 1);
numDotsNew = length(dotPosY);

% Filter the ones in the smaller circles

inSmall = dotPosX.^2 + dotPosY.^2 < circleRadsPix(2)^2;
smalldotPosX = dotPosX(inSmall == 1);
smalldotPosY = dotPosY(inSmall == 1);

% remove them from the bigger circle
bigdotPosX = dotPosX(inSmall == 0);
bigdotPosY = dotPosY(inSmall == 0);

% Dot diameter in pixels
dotDiaPix = 6;


%------------------------
% Drawing to the screen
%------------------------

% When drawing in stereo we have to select which eyes buffer we are going
% to draw in. These are labelled 0 for left and 1 for right. Note also, if
% you wear your anaglyph glasses the opposite way around the depth will
% reverse.


% define some keys
returnKey = KbName('RETURN');

leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
upKey = KbName('UpArrow');
downKey = KbName('DownArrow');

% Initialise the colors
if exist('Color.mat', 'file')
    C = open('Color.mat');

    leftC = C.leftC;
    rightC = C.rightC;
else
    leftC = [1.0 0.0 0.0];
    rightC = [0.0 1.0 0.0];
end

% loop while return is not pressed
pressedreturn = 0;   
frames = 0;
flicker = 0;
colorPos = 1;

while ~pressedreturn
    % get the keyCode of the Key being pressed
    [keyIsDown, ~, keyCode] = KbCheck;
    pressedreturn = keyCode(returnKey);
    
    
    if keyCode(rightKey)
        colorPos = min(3, colorPos +1);
        frames = 0;
        flicker = 0;
        WaitSecs(0.1);
    end
    if keyCode(leftKey)
        colorPos = max(1, colorPos -1);
        frames = 0;
        flicker = 0;
        WaitSecs(0.1);
        
    end
    if keyCode(upKey)
        rightC(colorPos) = round(min(1,rightC(colorPos)+0.05),2);
        frames = 0;
        flicker = 0;
        WaitSecs(0.1);
    end
    if keyCode(downKey)
        rightC(colorPos) = round(max(0,rightC(colorPos)-0.05),2);
        frames = 0;
        flicker = 0;
        WaitSecs(0.1);
    end
    
    toptext = 'First, select color for the right stereoglyph, current value:';
    currentvalueText = "[" + num2str(rightC(1), '%.2f') + ", " + num2str(rightC(2), '%.2f') + ", " + num2str(rightC(3), '%.2f') + "]";    
    bottomtext = 'Press return, when both circles appear to be the same color';
    IndicatorTop = '^';
    IndicatorBot = 'v';
    
    % set the outer ring to white, we want to test the inner ring.
    SetAnaglyphStereoParameters('LeftGains', window, [1.0 1.0 1.0]);
    SetAnaglyphStereoParameters('RightGains', window, rightC);
    
    
    % Select left-eye image buffer for drawing (buffer = 0)
    Screen('SelectStereoDrawBuffer', window, 0);

    % Now draw our white eyes dots
    Screen('DrawDots', window, [bigdotPosX; bigdotPosY], dotDiaPix,...
        [], [screenXpix / 2 screenYpix / 2], 2);
    
    Screen('TextSize', window, 24);
    Screen('DrawText', window, toptext, 380.0, 50.0, [1.0 1.0 1.0]);
    Screen('DrawText', window, char(currentvalueText), 1350.0, 50.0, [1.0 1.0 1.0]);
    Screen('DrawText', window, bottomtext, 400.0, 1000.0, [1.0 1.0 1.0]);
    
    if 0 == mod(frames, 19)
        flicker = ~flicker;
    end
    if flicker
        Screen('TextSize', window, 14);
        Screen('DrawText', window, IndicatorTop, 1329.0 + 70*colorPos, 40.0, [1.0 1.0 1.0]);
        Screen('TextSize', window, 11);
        Screen('DrawText', window, IndicatorBot, 1330.0+ 70*colorPos, 90.0, [1.0 1.0 1.0]);
    end
    
    % Select right-eye image buffer for drawing (buffer = 1)
    Screen('SelectStereoDrawBuffer', window, 1);
    
    
    % Now draw our colored eyes dots
    Screen('DrawDots', window, [smalldotPosX; smalldotPosY], dotDiaPix,...
       [], [screenXpix / 2 screenYpix / 2], 2);

    % Flip to the screen
    Screen('Flip', window);
    WaitSecs(0.01);
    frames = frames +1;
end
save('Color.mat', 'rightC');

% loop while return is not pressed
pressedreturn = 0;   
frames = 0;
flicker = 0;
colorPos = 1;

% so that the second loop does not get abortet right away 
WaitSecs(0.2);

while ~pressedreturn
    % get the keyCode of the Key being pressed
    [keyIsDown, ~, keyCode] = KbCheck;
    pressedreturn = keyCode(returnKey);
    
    if keyCode(rightKey)
        colorPos = min(3, colorPos +1);
        frames = 0;
        flicker = 0;
        WaitSecs(0.1);
    end
    if keyCode(leftKey)
        colorPos = max(1, colorPos -1);
        frames = 0;
        flicker = 0;
        WaitSecs(0.1);
    end
    if keyCode(upKey)
        leftC(colorPos) = round(min(1,leftC(colorPos)+0.05),2);
        frames = 0;
        flicker = 0;
        WaitSecs(0.1);
    end
    if keyCode(downKey)
        leftC(colorPos) = round(max(0,leftC(colorPos)-0.05),2);
        frames = 0;
        flicker = 0;
        WaitSecs(0.1);
    end
    
    toptext = 'Now, select color for the left stereoglyph, current value:';
    currentvalueText = "[" + num2str(leftC(1), '%.2f') + ", " + num2str(leftC(2), '%.2f') + ", " + num2str(leftC(3), '%.2f') + "]";    
    bottomtext = 'Press return, when both circles appear to be the same color';
    IndicatorTop = '^';
    IndicatorBot = 'v';
    
    % set the outer ring to white, we want to test the inner ring.
    SetAnaglyphStereoParameters('LeftGains', window, [1.0 1.0 1.0]);
    SetAnaglyphStereoParameters('RightGains', window, leftC);
    
    
    % Select left-eye image buffer for drawing (buffer = 0)
    Screen('SelectStereoDrawBuffer', window, 0);

    % Now draw our white eyes dots
    Screen('DrawDots', window, [bigdotPosX; bigdotPosY], dotDiaPix,...
        [], [screenXpix / 2 screenYpix / 2], 2);
    
    Screen('TextSize', window, 24);
    Screen('DrawText', window, toptext, 400.0, 50.0, [1.0 1.0 1.0]);
    Screen('DrawText', window, char(currentvalueText), 1350.0, 50.0, [1.0 1.0 1.0]);
    Screen('DrawText', window, bottomtext, 400.0, 1000.0, [1.0 1.0 1.0]);
    
    if 0 == mod(frames+1, 19)
        flicker = ~flicker;
    end
    if flicker
        Screen('TextSize', window, 14);
        Screen('DrawText', window, IndicatorTop, 1329.0 + 70*colorPos, 40.0, [1.0 1.0 1.0]);
        Screen('TextSize', window, 11);
        Screen('DrawText', window, IndicatorBot, 1330.0+ 70*colorPos, 90.0, [1.0 1.0 1.0]);
    end
    
    % Select right-eye image buffer for drawing (buffer = 1)
    Screen('SelectStereoDrawBuffer', window, 1);
    
    
    % Now draw our colored eyes dots
    Screen('DrawDots', window, [smalldotPosX; smalldotPosY], dotDiaPix,...
       [], [screenXpix / 2 screenYpix / 2], 2);

    % Flip to the screen
    Screen('Flip', window);
    WaitSecs(0.01);
    frames = frames +1;
end
save('Color.mat', 'leftC', '-append');

% Wait for a button press to exit the demo
KbStrokeWait;
sca;