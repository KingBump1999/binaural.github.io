%% tidy up
clc
clear
close all

%% add paths
addpath('AudioFiles')
addpath('Functions')
addpath('FX')

%% start timer
tic

%% Read Audiofiles
% Voices

[V1,fs] = audioread("Female-1.wav"); %Read in voice line 1
 V2     = audioread("Female-2.wav");%Read in voice line 2

% Ambient Whispering
W1 = audioread("Whispers.wav"); %Read in ambience audio file

% Tense Heartbeat
H1 = audioread("Heartbeat.wav");%read in audio file

% height HRIR
% this is at 0 azimuth, 90 elevation
HRIR_height1 = audioread('azi_0,0_ele_90,0.wav');
% this is at 180 azimuth, -45 elevation
HRIR_height2 = audioread('azi_180,0_ele_-45,0.wav');

%% Processing

%Female Voice 1
V1 = V1/max(V1); %normalize 
V1 = V1(:,1);%convert to mono
V1flange = flanger (V1,fs,0.05,1/5);%Apply flanger to audio source
V1traj = linspace(0,360,10000);%Assign trajectory
V1Pan  = panHRIR(V1flange,512,V1traj);%Pan from Right to Left over length of file

%Female Voice 2
V2 = V2/max(V2);
V2 = V2(:,1);%convert to mono
V2traj = linspace(360,0,10000);%Assign Trajectory
V2Pan  = panHRIR(V2,512,V2traj);%Pan from Left to Right over length of file


%Ambient Whispers
W1 = W1(:,1);%convert to mono
rampTime = linspace(0,1,length(W1));%create rampTime with linspace
scaledW1 = W1.*rampTime';%scale W1 
scaledW1 = 0.1* scaledW1;%Fix max amplitude as 0.1 of original
scaledW1convL = conv(scaledW1,HRIR_height2(:,1)); %Convulve with left channel IR
scaledW1convR = conv(scaledW1,HRIR_height2(:,2));%Convulve with right channel IR
scaledW1conv  = [scaledW1convL scaledW1convR];%concatenate
scaledW1conv  = 0.3*scaledW1conv/max(abs(scaledW1conv(:)));%Normalize 

%Heartbeat
H1 = H1(:,1);
H1 = 0.1*H1;
H1convL = conv(H1,HRIR_height1(:,1)); 
H1convR = conv(H1,HRIR_height1(:,2));
H1conv  = [H1convL H1convR];
H1conv  = H1conv/max(abs(H1conv(:)));


%% Combine processed audio

V1N=length(V1Pan);
V2N=length(V2Pan);
H1N=length(H1conv);
W1N=length(scaledW1conv);

yN = max([W1N,H1N,V1N,V2N]);y = zeros(yN,2);

y(1:V1N,:)=y(1:V1N,:) + V1Pan;
y(1:V2N,:)=y(1:V2N,:) + V2Pan;
y(1:H1N,:)=y(1:H1N,:) + H1conv;
y(1:W1N,:)=y(1:W1N,:) + scaledW1conv;

y=y/max(abs(y(:)));

%% end timer
toc

%% Stereo output written to file
audiowrite('BinauralMix.wav',y,fs);