%% Initial Setup
% Make a clean sweep:
clear all
close all
clc

% Params
dt = 0.05;
tSTART = 0;
tMAX = 60;

%% Set up model:
% model = Mdl_DifferentialDriveCLASS();
model = Mdl_TractorTrailerCLASS();
% model = Mdl_BicycleCLASS();

%% Initial state
q0 = zeros(model.nx, 1);
q0 = [model.length_front + model.length_back;0.1;0;0;0;0];

%% Set up trajectory:
trajectory = Ref_EightCurveCLASS(model);
% trajectory = Ref_CoveragePathCLASS(model);
% trajectory = Ref_HalfCircleCLASS(model);
trajectory.tMAX   = tMAX;                      % maximum simulation time
trajectory.dt = dt; 
trajectory.mode = "load";
trajectory = trajectory.Generate();

%% Set up controller:
% controller = Ctrl_FeedForwardCLASS(model, trajectory);
controller = Ctrl_MPControlCLASS(model, trajectory);
% controller = Ctrl_PurepursuitCLASS(model, trajectory);
% controller = Ctrl_StanleyCLASS(model, trajectory);

%% Set up observer; 
observer = Obs_NormalCLASS(model, true);
observer.noise_sigma = diag(ones(model.nx, 1))*1e-2;

%% Set up simultion: 
simulation = TimeSteppingCLASS(model, trajectory, controller, observer);
simulation.tSTART = tSTART;                       % initial time
simulation.tMAX   = tMAX;                      % maximum simulation time
simulation.dt = dt; 

%% Run simulation
simulation = simulation.Run(q0);

%% Set up animation:
animation = AnimationCLASS(model, trajectory, controller, simulation);
animation.Animate();
animation.Plot();

