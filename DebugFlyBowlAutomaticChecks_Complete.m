%% set up path


[~,computername] = system('hostname');
computername = strtrim(computername);

switch computername,
  
  case 'bransonk-lw1',
    
    addpath E:\Code\JCtrax\misc;
    addpath E:\Code\JCtrax\filehandling;
    addpath('E:\Code\SAGE\MATLABInterface\Trunk\')
    settingsdir = 'E:\Code\FlyBowlAnalysis\settings';
    rootdatadir = 'O:\Olympiad_Screen\fly_bowl\bowl_data';
  
  case 'bransonk-lw2',

    addpath C:\Code\JCtrax\misc;
    addpath C:\Code\JCtrax\filehandling;
    addpath('C:\Code\SAGE\MATLABInterface\Trunk\')
    settingsdir = 'C:\Code\FlyBowlAnalysis\settings';
    rootdatadir = 'O:\Olympiad_Screen\fly_bowl\bowl_data';
    
  case 'bransonk-desktop',
    
    addpath /groups/branson/home/bransonk/tracking/code/JCtrax/misc;
    addpath /groups/branson/home/bransonk/tracking/code/JCtrax/filehandling;
    addpath /groups/branson/bransonlab/projects/olympiad/SAGE/MATLABInterface/Trunk;
    settingsdir = '/groups/branson/bransonlab/projects/olympiad/FlyBowlAnalysis/settings';
    rootdatadir = '/groups/sciserv/flyolympiad/Olympiad_Screen/fly_bowl/bowl_data';

  otherwise
    
    warning('Unknown computer %s. Paths may not be setup correctly',computername);
    addpath C:\Code\JCtrax\misc;
    addpath C:\Code\JCtrax\filehandling;
    addpath('C:\Code\SAGE\MATLABInterface\Trunk\')
    settingsdir = 'C:\Code\FlyBowlAnalysis\settings';
    rootdatadir = 'O:\Olympiad_Screen\fly_bowl\bowl_data';
    
end

%% parameters

analysis_protocol = '20110804';

%% choose experiments

expdir = fullfile(rootdatadir,'pBDPGAL4U_TrpA_Rig1Plate10BowlA_20110714T110950');
data = SAGEListBowlExperiments('daterange',{'20110601T000000'},'automated_pf','F','checkflags',false,'removemissingdata',false,'rootdir',rootdatadir);

expdirs = {data.file_system_path};

%%

success = [];
msg = {};
iserror = {};

errors_seen = [];
for i = i:numel(expdirs),
  expdir = expdirs{i};
  disp(data(i).experiment_name);
  [success(i),msg{i},iserror{i}] = FlyBowlAutomaticChecks_Complete(expdir,'settingsdir',settingsdir,'analysis_protocol',analysis_protocol,'debug',true);
  if ~success(i),
    if any(~ismember(find(iserror{i},1),errors_seen)),
      input('');
      errors_seen = union(errors_seen,find(iserror{i},1));
    end
  end
end