clear all; close all; clc;
% figure('MenuBar','none','ToolBar','none');


projectName = 'FVEdemoSim';
%%%%%%%%%%%%%%%%%%%%%
%% Set up environment
%%%%%%%%%%%%%%%%%%%%%

% Detect computing environment
os   = char(java.lang.System.getProperty('os.name'));
host = char(java.net.InetAddress.getLocalHost.getHostName);
user = char(java.lang.System.getProperty('user.name'));

% Setup folders
if strcmp(os,'Linux') && strcmp(host,'takoyaki') && strcmp(user,'sebp')
    envId      = 1;
    storageDrive = '/local/users/Proulx-S/';
    scratchDrive = '/scratch/users/Proulx-S/';
    projectCode    = fullfile(scratchDrive, projectName);        if ~exist(projectCode,'dir');    mkdir(projectCode);    end
    projectStorage = fullfile(storageDrive, projectName);        if ~exist(projectStorage,'dir'); mkdir(projectStorage); end
    projectScratch = fullfile(scratchDrive, projectName, 'tmp'); if ~exist(projectScratch,'dir'); mkdir(projectScratch); end
    toolDir        = '/scratch/users/Proulx-S/tools';            if ~exist(toolDir,'dir');        mkdir(toolDir);        end
else
    envId = 2;
    storageDrive   = '/Users/sebastienproulx/';
    scratchDrive   = '/Users/sebastienproulx/';
    projectCode    = fullfile(scratchDrive, projectName);        if ~exist(projectCode,'dir');    mkdir(projectCode);    end
    projectStorage = fullfile(storageDrive, projectName);        if ~exist(projectStorage,'dir'); mkdir(projectStorage); end
    projectScratch = fullfile(scratchDrive, projectName, 'tmp'); if ~exist(projectScratch,'dir'); mkdir(projectScratch); end
    toolDir        = '/Users/sebastienproulx/tools';             if ~exist(toolDir,'dir');        mkdir(toolDir);        end
end

% Load dependencies and set paths
%%% initial cloning of matlab util to get gitClone.m
tool = 'util'; toolURL = 'https://github.com/Proulx-S/util.git';
if ~exist(fullfile(toolDir, tool), 'dir'); system(['git clone ' toolURL ' ' fullfile(toolDir, tool)]); end; addpath(genpath(fullfile(toolDir,tool)))
%%% matlab others
tool = 'util'; repoURL = 'https://github.com/Proulx-S/util.git'; branch = 'dev-FVEdemoSim';
gitClone(repoURL, fullfile(toolDir, tool), [], branch);
tool = 'pcMRAsim'; repoURL = 'https://github.com/Proulx-S/pcMRAsim.git'; branch = 'dev-FVEdemoSim';
gitClone(repoURL, fullfile(toolDir, tool), [], branch);

%% %%%%%%%%%%%%%%%%%%
disp(projectCode)
disp(projectStorage)
disp(projectScratch)
info.project.code    = projectCode;
info.project.storage = projectStorage;
info.project.scratch = projectScratch;
info.toClean = {};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set-up simulation parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
M1List   = 0:vencToM1(50):vencToM1(2);
M1ListBi = cat(2,-flip(M1List(2:end)),M1List);
vRes = M1toVenc(mean(diff(M1List)));
vMax = M1toVenc(max(M1List));
%% %%%%%%%%%%%%%%

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulate vessel at mean(diameter,velocity)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pVessel.x0         = [];   % [mm] vessel center x           | default 0
pVessel.y0         = [];   % [mm] vessel center y           | default 0
pVessel.ID         = [];   % [mm] vessel inner diameter     | default 1
pVessel.PD         = [];   % [mm] plug flow center diameter | default 0
pVessel.WT         = [];   % [mm] vessel wall thickness     | default 0
pVessel.profile    = [];   %                                | default 'parabolic1'
pVessel.vMax       = [];   % [cm/s] maximum cross-sectional velocity | default 20
pVessel.vMean      = [];   % [cm/s] cross-sectional mean velocity    | default 10
pVessel.vFlow      = [];   % [ml/min] vessel flow | default ?
pVessel.S.lumenLami = [0.05 0.3];  % [{0,1}au] 1 values->no inflow enhancement, 2 values->linear inflow enhancement from first to second value | default blood at 7T (requires acquistion parameters)
pVessel.S.lumenPlug = [];  % same as lumenLami
pVessel.S.wall      = [];  %           | default 0
pVessel.S.surround  = [];  % [{0,1}au] | default blood at 7T (requires acquistion parameters)
% pVessel.inflow = inflow; % inflow enhancement related parameters (T1, TR, FA, etc.)
% pVessel.T1     = T1;
% pVessel.T2star = T2star;

pSim.voxFE        = 1;       % [mm]      | default 1
pSim.voxPE        = 1;       % [mm]      | default voxFE
pSim.matFE        = 1;       % [voxels] must be odd      | default 3
pSim.matPE        = 1;       % [voxels] must be odd      | default matFE
pSim.fovBoot      = 2^7;     % [number of bootstrap random object-to-grid shifts] | default 2^7 = 128
pSim.nSpin        = (2^8)^2; % [number of spins per voxel] | default (2^8)^2 = 2^16 = 65,536



pMri.relax.blood.T1     = 2.58; % [s] | default human in vivo at 7T
% Blood T1. Human at 7T (Rane & Gore, Magn Reson Imaging 31(3):477–479, 2013, doi:10.1016/j.mri.2012.08.008):
%   arterial 2.29±0.10 s, venous 2.07±0.12 s in vitro (37°C); venous sagittal sinus in vivo 2.45±0.11 s.
%   arterial in vivo 2.45/2.07*2.29 = 2.71 s
%   mid arterio-venous in vivo (2.71+2.45)/2 = 2.58 s
pMri.relax.blood.T2star = 0.01; % [s] | default human in vivo at 7T
% Blood T2*. Human at 7T: venous blood ~7.4 ms (SWI/venography at 7T); arterial longer (higher oxygenation).
%   Blood T2* is strongly oxygenation-dependent; R2* increases with deoxyhemoglobin (e.g. Qin & van Zijl, MRM 24868, 2009).
pMri.relax.GM.T1        = 1.939; % [s] | default human in vivo at 7T
% Gray matter cortical T1. Human at 7T (Waddell et al., MAGMA 21:121–130, 2008, doi:10.1007/s10334-008-0104-8):
%   cortical gray matter 1939±149 ms (~1.94 s), white matter 1126±97 ms (MPRAGE, 4 subjects).
pMri.relax.GM.T2star    = 0.0329; % [s] | default human in vivo at 7T
% Gray matter cortical T2*. Human at 7T (Peters et al., Magn Reson Imaging 25:748–753, 2007, doi:10.1016/j.mri.2007.02.014):
%   cortical gray matter 32.9±2.3 ms, white matter 27.7±4.3 ms at 7T (six subjects).
pMri.sliceThickness = [];% [mm]   | default 1
pMri.TR             = 0.05; % [s]    | default 50 ms
pMri.FA             = 35;   % [deg]  | default 40 deg
pMri.venc.vencRes   = 2;    % [cm/s] | default 2
pMri.venc.vencMax   = 50;   % [cm/s] | default 50
pMri.venc.vencList  = M1toVenc(M1ListBi);      % [cm/s] | default [0 8] or a list built from vencRes and vencMax





res = runSim(pVessel, pSim, pMri);
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pVesselOrig;
res;
