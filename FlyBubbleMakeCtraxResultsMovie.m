% make results movies
function FlyBubbleMakeCtraxResultsMovie(expdir,varargin)

[analysis_protocol,settingsdir,datalocparamsfilestr] = ...
  myparse(varargin,...
  'analysis_protocol','20150915_flybubble_centralcomplex',...
  'settingsdir','/groups/branson/home/robiea/Code_versioned/FlyBubbleAnalysis/settings',...
  'datalocparamsfilestr','dataloc_params.txt');

%% locations of parameters

datalocparamsfile = fullfile(settingsdir,analysis_protocol,datalocparamsfilestr);
dataloc_params = ReadParams(datalocparamsfile);

%% location of data

[~,basename,~] = fileparts(expdir);
moviefile = fullfile(expdir,dataloc_params.moviefilestr);
trxfile = fullfile(expdir,dataloc_params.trxfilestr);
avifilestr = sprintf('%s_%s',dataloc_params.ctraxresultsavifilestr,basename);
%xvidfile = fullfile(expdir,[avifilestr,'.avi']);
indicatorfile = fullfile(expdir,dataloc_params.indicatordatafilestr);
% metadatafile = fullfile(expdir,'Metadata.xml');
metadatafile = fullfile(expdir,dataloc_params.metadatafilestr);
metadata = ReadMetadataFile(metadatafile);
% commonregistrationparamsfile = fullfile(settingsdir,analysis_protocol,'registration_params.txt');
commonregistrationparamsfile = fullfile(settingsdir,analysis_protocol,dataloc_params.registrationparamsfilestr);
commonregistrationparams = ReadParams(commonregistrationparamsfile);
if commonregistrationparams.OptogeneticExp,
  datestrpattern = '20\d{6}';
  match = regexp(metadata.led_protocol,datestrpattern);
  
  ledprotocoldatestr = metadata.led_protocol(match:match+7);
%   ledprotocolfile = fullfile(expdir,'protocol.mat');
  ledprotocolfile = fullfile(expdir,dataloc_params.ledprotocolfilestr);
  
end

%% ctrax movie parameters
defaultctraxresultsmovieparamsfile = fullfile(settingsdir,analysis_protocol,dataloc_params.ctraxresultsmovieparamsfilestr);
if commonregistrationparams.OptogeneticExp,
  specificctraxresultsmovie_paramsfile = fullfile(settingsdir,analysis_protocol,['ctraxresultsmovie_params_',ledprotocoldatestr,'.txt']);
  defaultparams = 1;
  if exist(specificctraxresultsmovie_paramsfile,'file'),
    ctraxresultsmovie_params = ReadParams(specificctraxresultsmovie_paramsfile);
    defaultparams = 0;
  else
    ctraxresultsmovie_params = ReadParams(defaultctraxresultsmovieparamsfile);
  end
else
%  ctraxresultsmovie_params_nonoptogenetic.txt doesn't exist as far as I can tell   
  specificctraxresultsmovie_paramsfile = fullfile(settingsdir,analysis_protocol,'ctraxresultsmovie_params_nonoptogenetic.txt');
  ctraxresultsmovie_params = ReadParams(specificctraxresultsmovie_paramsfile);
  defaultparams = 0;
end
defaulttempdatadir = '/groups/branson/bransonlab/projects/olympiad/TempData_FlyBowlMakeCtraxResultsMovie';
avifile = fullfile(ctraxresultsmovie_params.tempdatadir,[avifilestr,'_temp.avi']);
mp4file = fullfile(expdir,[avifilestr,'.mp4']);

if ~isfield(ctraxresultsmovie_params,'tempdatadir'),
  ctraxresultsmovie_params.tempdatadir = defaulttempdatadir;
elseif isunix
  [status1,res] = unix(sprintf('echo %s',ctraxresultsmovie_params.tempdatadir));
  if status1 == 0,
    ctraxresultsmovie_params.tempdatadir = strtrim(res);
  end
end

if ~exist(ctraxresultsmovie_params.tempdatadir,'dir'),
  [success1,msg1] = mkdir(ctraxresultsmovie_params.tempdatadir);
  if ~success1,
    error('Error making directory %s: %s',ctraxresultsmovie_params.tempdatadir,msg1);
  end
end

%% read start and end of cropped trajectories

registrationtxtfile = fullfile(expdir,dataloc_params.registrationtxtfilestr);
if ~exist(registrationtxtfile,'file'),
  load(trxfile,'trx');
  registration_params.end_frame = max([trx.endframe]);
  registration_params.start_frame = min([trx.firstframe]);
else
  registration_params = ReadParams(registrationtxtfile);
  if ~isfield(registration_params,'end_frame'),
    load(trxfile,'trx');
    registration_params.end_frame = max([trx.endframe]);
  end
  if ~isfield(registration_params,'start_frame'),
    if ~exist('trx','var'),
      load(trxfile,'trx');
    end
    registration_params.start_frame = min([trx.firstframe]);
  end
end

%% determine start and end frames of snippets

if ~commonregistrationparams.OptogeneticExp,
  nframes = registration_params.end_frame-registration_params.start_frame + 1;
  firstframes_off = min(max(0,round(ctraxresultsmovie_params.firstframes*nframes)),nframes-1);
  firstframes_off(ctraxresultsmovie_params.firstframes < 0) = nan;
  middleframes_off = round(ctraxresultsmovie_params.middleframes*nframes);
  middleframes_off(ctraxresultsmovie_params.middleframes < 0) = nan;
  endframes_off = round(ctraxresultsmovie_params.endframes*nframes);
  endframes_off(ctraxresultsmovie_params.endframes < 0) = nan;
  idx = ~isnan(middleframes_off);
  firstframes_off(idx) = ...
   min(nframes-1,max(0,middleframes_off(idx) - ceil(ctraxresultsmovie_params.nframes(idx)/2)));
  idx = ~isnan(endframes_off);
  firstframes_off(idx) = ...
   min(nframes-1,max(0,endframes_off(idx) - ctraxresultsmovie_params.nframes(idx)));
  endframes_off = firstframes_off + ctraxresultsmovie_params.nframes - 1;
  firstframes = registration_params.start_frame + firstframes_off;
else
  if defaultparams,
    load(indicatorfile)
    load(ledprotocolfile)
    nsteps = numel(protocol.stepNum);
    
    if nsteps == 1,
      iter = protocol.iteration;
      n = ceil(iter/6);     % take every nth iteration of the stimulus
      indicatorframes = 1:n:iter;
    elseif nsteps <= 3,
      indicatorframes = zeros(1,2*nsteps);
      for step = 1:nsteps,
        iter = protocol.iteration(step);
        if step==1,
          indicatorframes(1)=1;
          indicatorframes(2)=iter;
        else
          indicatorframes(2*step-1)=indicatorframes(2*step-2)+1;
          indicatorframes(2*step)=indicatorframes(2*step-1);
        end        
      end
    else
      n = ceil(nsteps/6);
      index = 1;
      indicatorframes=ones(1,numel(1:n:nsteps));
      for step = 1:n:nsteps,
        if step==1,
          indicatorframes(index)=1;
          index=index+1;
        else
          indicatorframes(index) = indicatorframes(index-1);
          for i = step-n:step-1
            indicatorframes(index) = indicatorframes(index)+protocol.iteration(i);
          end
          index=index+1;
          
        end
      end
    end
    
    % make sure none of the steps are blank (have no stimulus)
    stim = 0;
    step = 0;
    for i=1:numel(indicatorframes),
      while indicatorframes(i) > stim,
        step=step+1;
        stim = stim+protocol.iteration(step);
      end
      if (protocol.intensity(step) == 0),
        if ~(i==numel(indicatorframes)),
          error('Step with intensity = 0 in middle of experiment. User needs to make specific ctrax results movie params file')
        end
        indicatorframes(i) = [];
      end
    end
    
    ctraxresultsmovie_params.indicatorframes = indicatorframes;
    firstframes_off = indicatorLED.startframe(indicatorframes) - ctraxresultsmovie_params.nframes_beforeindicator;    
    ctraxresultsmovie_params.nframes = ones(1,length(firstframes_off))*ctraxresultsmovie_params.nframes;
    endframes_off = firstframes_off + ctraxresultsmovie_params.nframes -1;
    firstframes = registration_params.start_frame + firstframes_off;
  else
    if exist(indicatorfile,'file')
      load(indicatorfile)
      firstframes_off = indicatorLED.startframe(ctraxresultsmovie_params.indicatorframes) - ctraxresultsmovie_params.nframes_beforeindicator;
      endframes_off = firstframes_off + ctraxresultsmovie_params.nframes -1 ;
      firstframes = registration_params.start_frame + firstframes_off;
    end
  end
end

%% option to not specify nzoomr, nzoomc

if ischar(ctraxresultsmovie_params.nzoomr) || ischar(ctraxresultsmovie_params.nzoomc),
  
  % figure out number of flies
  load(trxfile,'trx');
  
  firstframe = min([trx.firstframe]);
  endframe = max([trx.endframe]);
  trxnframes = endframe-firstframe+1;
  nflies = zeros(1,trxnframes);
  for i = 1:numel(trx),
    j0 = trx(i).firstframe-firstframe+1;
    j1 = trx(i).endframe-firstframe+1;
    nflies(j0:j1) = nflies(j0:j1)+1;
  end
  mediannflies = median(nflies);

  if isnumeric(ctraxresultsmovie_params.nzoomr),
    nzoomr = ctraxresultsmovie_params.nzoomr;
    nzoomc = round(mediannflies/nzoomr);
  elseif isnumeric(ctraxresultsmovie_params.nzoomc),
    nzoomc = ctraxresultsmovie_params.nzoomc;
    nzoomr = round(mediannflies/nzoomc);
  else
    nzoomr = ceil(sqrt(mediannflies));
    nzoomc = round(mediannflies/nzoomr);
  end
  ctraxresultsmovie_params.nzoomr = nzoomr;
  ctraxresultsmovie_params.nzoomc = nzoomc;
  
  if iscell(ctraxresultsmovie_params.figpos),  
    [readframe,~,fid] = get_readframe_fcn(moviefile);
    im = readframe(1);
    [nr,nc,~] = size(im);
    
    rowszoom = floor(nr/nzoomr);
    imsize = [nr,nc+rowszoom*nzoomc];
    figpos = str2double(ctraxresultsmovie_params.figpos);
    if isnan(figpos(3)),
      figpos(3) = figpos(4)*imsize(2)/imsize(1);
    elseif isnan(figpos(4)),
      figpos(4) = figpos(3)*imsize(1)/imsize(2);
    end
    ctraxresultsmovie_params.figpos = figpos;
    
    if fid > 1,
      fclose(fid);
    end
  end
  
end

%% create subtitle file

subtitlefile = fullfile(expdir,'subtitles.srt');
fid = fopen(subtitlefile,'w');
dt = [0,ctraxresultsmovie_params.nframes];
ts = cumsum(dt);

if ~commonregistrationparams.OptogeneticExp,
  for i = 1:numel(dt)-1,
    fprintf(fid,'%d\n',i);
    fprintf(fid,'%s --> %s\n',...
     datestr(ts(i)/ctraxresultsmovie_params.fps/(3600*24),'HH:MM:SS,FFF'),...
     datestr((ts(i+1)-1)/ctraxresultsmovie_params.fps/(3600*24),'HH:MM:SS,FFF'));
    fprintf(fid,'%s, fr %d-%d\n\n',basename,...
     firstframes_off(i)+1,...
     endframes_off(i)+1);
  end
  fclose(fid);
else
    
  load(ledprotocolfile);
  load(indicatorfile);
  stimtimes = indicatorLED.starttimes(ctraxresultsmovie_params.indicatorframes);
    
  j = 1;
  t = protocol.duration(j)/1000;
  
  step = zeros(1,length(stimtimes));
  freq = zeros(1,length(stimtimes));
  intensity = zeros(1,length(stimtimes));
  dutycycle = zeros(1,length(stimtimes));
  duration = zeros(1,length(stimtimes));
  
  for i = 1:length(stimtimes),
    while stimtimes(i) > t
      j = j+1;
      t = t + protocol.duration(j)/1000;
    end
    
    step(i) = j;
    if protocol.pulseNum(j) > 1,
      freq(i) = 1/(protocol.pulsePeriodSP(j)/1000);
      stim_type{i} = ['Plsd ', num2str(freq(i)), 'Hz'];
    else
      stim_type{i} = 'Cnst';
    end
    
    intensity(i) = protocol.intensity(j);
    dutycycle(i) = (protocol.pulseWidthSP(j)/protocol.pulsePeriodSP(j))*100;
    duration(i) = protocol.pulseNum(j)*protocol.pulsePeriodSP(j);
    
  end
    
  for k = 1:numel(dt)-1,
    fprintf(fid,'%d\n',k);
    
    t_start = ts(k)/ctraxresultsmovie_params.fps/(3600*24);
    t_end = (ts(k) + (ts(k+1)-1-ts(k))/ctraxresultsmovie_params.subdecimationfactor)/ ...
        ctraxresultsmovie_params.fps/(3600*24);
     
    fprintf(fid,'%s --> %s\n',...
     datestr(t_start,'HH:MM:SS,FFF'),...
     datestr(t_end,'HH:MM:SS,FFF'));
    fprintf(fid,'%s\n%s %s %s %s %s %s\n\n',basename,...
     ['Step ', num2str(step(k))],...     
     ['(Stim ', num2str(ctraxresultsmovie_params.indicatorframes(k)),'/', ...
       num2str(numel(indicatorLED.starttimes)),'):'],...
     stim_type{k},...
     ['(',num2str(dutycycle(k)),'% on)'],...
     ['at ',num2str(intensity(k)), '% intensity'],...
     ['for ',num2str(duration(k)), ' ms']);
     
  end
  fclose(fid);
end


%% create movie

[succeeded,~,~,height,width]= ...
  make_ctrax_result_movie('moviename',moviefile,'trxname',trxfile,'aviname',avifile,...
  'nzoomr',ctraxresultsmovie_params.nzoomr,'nzoomc',ctraxresultsmovie_params.nzoomc,...
  'boxradius',ctraxresultsmovie_params.boxradius,'taillength',ctraxresultsmovie_params.taillength,...
  'fps',ctraxresultsmovie_params.fps,...
  'maxnframes',ctraxresultsmovie_params.nframes,...
  'firstframes',firstframes,...
  'figpos',ctraxresultsmovie_params.figpos,...
  'movietitle',basename,...
  'compression','none',...
  'useVideoWriter',false,...
  'titletext',false,...
  'avifileTempDataFile',[avifile,'-temp'],...
  'dynamicflyselection',true,...
  'doshowsex',true);
%'fps',ctraxresultsmovie_params.fps,...
    %'maxnframes',+ctraxresultsmovie_params.nframes,...
if ishandle(1),
  close(1);
end

if ~succeeded,
  error('Failed to create raw avi %s',avifile);
end

%% compress

%tmpfile = [xvidfile,'.tmp'];
newheight = 4*ceil(height/4);
newwidth = 4*ceil(width/4);


% subtitles are upside down, so encode with subtitles and flip, then flip
% again
%cmd = sprintf('mencoder %s -o %s -ovc xvid -xvidencopts fixed_quant=4 -vf scale=%d:%d,flip -sub %s -subfont-text-scale 2 -msglevel all=2',...
%  avifile,tmpfile,newwidth,newheight,subtitlefile);

nowstr = datestr(now,'yyyymmddTHHMMSSFFF');
passlogfile = sprintf('%s_%s',avifile,nowstr);
cmd = sprintf('/misc/local/ffmpeg-2.6.3/bin/ffmpeg -i %s -y -passlogfile %s -c:v h264 -pix_fmt yuv420p -s %dx%d -b:v 1600k -vf "subtitles=%s:force_style=''FontSize=10,FontName=Helvetica''" -pass 1 -f mp4 /dev/null',...
  avifile,passlogfile,newwidth,newheight,subtitlefile);
cmd2 = sprintf('/misc/local/ffmpeg-2.6.3/bin/ffmpeg -i %s -y -passlogfile %s -c:v h264 -pix_fmt yuv420p -s %dx%d -b:v 1600k -vf "subtitles=%s:force_style=''FontSize=10,FontName=Helvetica''" -pass 2 -f mp4 %s',...
  avifile,passlogfile,newwidth,newheight,subtitlefile,mp4file);

status = system(cmd);
if status ~= 0,
  fprintf('*****\n');
  warning('ffmpeg first pass failed.');
  fprintf('Need to run:\n');
  fprintf('%s\n',cmd);
%  cmd2 = sprintf('mencoder %s -o %s -ovc xvid -xvidencopts fixed_quant=4 -vf flip -msglevel all=2',...
%    tmpfile,xvidfile);
  fprintf('then\n');
  fprintf('%s\n',cmd2);
  fprintf('then delete %s %s* %s\n',avifile,passlogfile,subtitlefile);
  fprintf('*****\n');
else
%   cmd = sprintf('mencoder %s -o %s -ovc xvid -xvidencopts fixed_quant=4 -vf flip -msglevel all=2',...
%     tmpfile,xvidfile);
  status = system(cmd2);
  if status ~= 0,
    fprintf('*****\n');
    warning('ffmpeg second pass failed.');
    fprintf('Need to run:\n');
    fprintf('%s\n',cmd2);
    fprintf('then delete %s %s* %s\n',avifile,passlogfile,subtitlefile);
    fprintf('*****\n');    
  else
    %delete(tmpfile);
    delete(avifile);
    delete(subtitlefile);
    fname = [passlogfile '-*.log'];
    if isscalar(dir(fname))
      delete(fname);
    end    
    fname = [passlogfile '-*.log.mbtree'];
    if isscalar(dir(fname))
      delete(fname);
    end    
  end
end