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
p = runSim();
pVessel = p.pVessel;
pSim    = p.pSim;
pMri    = p.pMri; clear p;

pMri.venc.method = 'FVEbipo';
pMri.venc.vencRes = 1;
pMri.venc.vencMax = 50;

pVessel1 = pVessel;
pVessel1.profile = 'parabolic1';
pVessel1.vMean = 4;
res1 = runSim(pVessel1, pSim, pMri);
pVessel2 = pVessel;
pVessel2.vMean = 0;
pVessel2.profile = 'plug';
res2 = runSim(pVessel2, pSim, pMri);
pVessel3 = pVessel;
pVessel3.vMean = 0;
pVessel3.profile = 'plug';
res3 = runSim(pVessel3, pSim, pMri);

Ns = length(res1.pMri.venc.vencList);
f = linspace(-res1.pMri.venc.vencMax,res1.pMri.venc.vencMax,Ns);
figure;
I = res1.I+res2.I+res3.I;
plot(f,abs(fftshift(fft(squeeze(I)))),'.-')
axis tight
xlabel('velocity [cm/s]')
grid on
% ylim([-pi,pi])
yscale('linear')
xlim([-50,50])




%% %%%%%%%%%%%%%%
