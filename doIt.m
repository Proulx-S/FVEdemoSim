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

pVessel.profile = 'plug';
pVessel.S.lumen    = 1;
pVessel.S.wall     = 0;
pVessel.S.surround = 1;

pVessel1 = pVessel;
pVessel2 = pVessel;
pVessel1.vMean = 10;
pVessel2.vMean = -14;

% Bipolar FVE
pMri.venc.method = 'FVEbipo';
pMri.venc.vencRes = 1;
pMri.venc.vencMax = 50;

res1 = runSim(pVessel1, pSim, pMri);
res2 = runSim(pVessel2, pSim, pMri);

vel = [res1.vMap(res1.pSim.gridVoxIdx==0) res2.vMap(res2.pSim.gridVoxIdx==0)];
I   = squeeze(res1.I+res2.I);
Ns  = length(I);
f   = linspace(-pMri.venc.vencMax,pMri.venc.vencMax,Ns);

bipo.vel = vel;
bipo.I   = I;
bipo.Ns  = Ns;
bipo.f   = f;


% Monopolar FVE
pMri.venc.method = 'FVEmono';
pMri.venc.vencRes = 1;
pMri.venc.vencMax = 50;

res1 = runSim(pVessel1, pSim, pMri);
res2 = runSim(pVessel2, pSim, pMri);

vel = [res1.vMap(res1.pSim.gridVoxIdx==0) res2.vMap(res2.pSim.gridVoxIdx==0)];
I   = squeeze(res1.I+res2.I);
Ns  = length(I);
f   = linspace(-pMri.venc.vencMax,pMri.venc.vencMax,Ns);

mono.vel = vel;
mono.I   = I;
mono.Ns  = Ns;
mono.f   = f;

% Plot
figure;
hT = tiledlayout(2,1); hT.TileSpacing = 'compact'; hT.Padding = 'compact'; ax = {};

ax{end+1} = nexttile;
[N,edges] = histcounts(mono.vel);
hH = histogram('BinEdges',edges,'BinCounts',N/max(N),'FaceColor',0.5.*[1 1 1],'EdgeColor','none');
hold on
vSpec = fftshift(fft(mono.I));
plot(mono.f,abs(vSpec)./max(abs(vSpec)),'.-w')
ylabel('spectrum mag or spin count');
% yyaxis right
% plot(mono.f,angle(vSpec),'.-'); ylim([-pi,pi])
xline(res1.pVessel.vMean,'-','color','r');
xline(res2.pVessel.vMean,'-','color','r');
ax{end}.XAxis.Visible = 'off';
grid on
title('Monopolar FVE');
legend('true spin count','velocity spectrum','true velocity','location','northwest');

% ylabel('spectrum phase');

ax{end+1} = nexttile;
[N,edges] = histcounts(bipo.vel);
hH = histogram('BinEdges',edges,'BinCounts',N/max(N),'FaceColor',0.5.*[1 1 1],'EdgeColor','none');
hold on
vSpec = fftshift(fft(bipo.I));
plot(bipo.f,abs(vSpec)./max(abs(vSpec)),'.-w')
ylabel('spectrum mag or spin count');
% yyaxis right
% plot(bipo.f,angle(vSpec),'.-'); ylim([-pi,pi])
xline(res1.pVessel.vMean,'-','color','r');
xline(res2.pVessel.vMean,'-','color','r');
grid on
xlabel('velocity (cm/s)');
title('Bipolar FVE');
% ylabel('spectrum phase');


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%