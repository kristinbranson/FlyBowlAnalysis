function trx = FlyBubbleComputePerFrameFeatures(expdir,varargin)

version = '0.2';

[analysis_protocol,settingsdir,datalocparamsfilestr,forcecompute,perframefns,DEBUG] = ...
  myparse(varargin,...
  'analysis_protocol','current_bubble',...
  'settingsdir','/groups/branson/home/robiea/Code_versioned/FlyBubbleAnalysis/settings',...
  'datalocparamsfilestr','dataloc_params.txt',...
  'forcecompute',true,...
  'perframefns', {}, ... % added CSC 20110321: optionally specify to-be-computed frames as parameter, reads from perframefnsfile (as before) otherwise
  'DEBUG',false...
	);

if ischar(forcecompute),
  forcecompute = str2double(forcecompute) ~= 0;
end

datalocparamsfile = fullfile(settingsdir,analysis_protocol,datalocparamsfilestr);
dataloc_params = ReadParams(datalocparamsfile);

%% 
logger = PipelineLogger(expdir,mfilename(),dataloc_params,'perframefeature_logfilestr',...
  settingsdir,analysis_protocol,'versionstr',version,'debug',DEBUG);

%% Init trx
logger.log('Initializing trx...\n');
trx = FBATrx('analysis_protocol',analysis_protocol,'settingsdir',settingsdir,...
  'datalocparamsfilestr',datalocparamsfilestr,'DEBUG',DEBUG);

%% Cleanup/log existing perframefns
perframefnsfile = fullfile(trx.settingsdir,trx.analysis_protocol,trx.dataloc_params.perframefnsfilestr);
if isempty(perframefns),
  perframefns = importdata(perframefnsfile);
end
nfns = numel(perframefns);

% what files exist already
tmp = dir(fullfile(expdir,trx.dataloc_params.perframedir,'*.mat'));
perframefns_preexist = regexprep({tmp.name},'\.mat$','');

% clean this data to force computation
if forcecompute,
  WINGTRACK_PERFRAMEFILES = {'nwingsdetected' 'wing_areal' 'wing_arear' 'wing_trough_angle'};
  % AL 20131016: Blow away all preexisting (sans wingtracking) to account for obsolete perframefns  
  perframefns_rm = setdiff(perframefns_preexist,WINGTRACK_PERFRAMEFILES);
  for i = 1:numel(perframefns_rm)
    pfftmp = fullfile(expdir,trx.dataloc_params.perframedir,[perframefns_rm{i} '.mat']);
    logger.log('Deleting per-frame data file %s\n',perframefns_rm{i});
    delete(pfftmp);
  end
end

%% Load trx
logger.log('Loading trajectories for %s...\n',expdir);
trx.AddExpDir(expdir,'openmovie',false,'tryloadwingtrx',false); % writes trajectory fns to perframe dir

%% compute per-frame features
for i = 1:nfns,
  try
    fn = perframefns{i};
    logger.log('Computing %s...\n',fn);
    trx.(fn); 
  catch ME
    fprintf(2,'Error occurred computing fn ''%s''\n',fn);
    disp(ME.getReport());
  end    
end

%% save info to a mat file

filename = fullfile(expdir,trx.dataloc_params.perframeinfomatfilestr);
logger.log('Saving debug info to file %s...\n',filename);
cpffinfo = logger.runInfo;
cpffinfo.perframefns = perframefns;
cpffinfo.forcecompute = forcecompute;
cpffinfo.perframefns_preexist = perframefns_preexist;
cpffinfo.landmark_params = trx.landmark_params;
cpffinfo.perframe_params = trx.perframe_params; 

if exist(filename,'file'),
  try %#ok<TRYNC>
    delete(filename);
  end
end
try
  save(filename,'-struct','cpffinfo');
catch ME
  warning('FlyBubbleComputePerFrameFeatures:save',...
    'Could not save information to file %s: %s',filename,getReport(ME));
end

%% 
logger.close();
