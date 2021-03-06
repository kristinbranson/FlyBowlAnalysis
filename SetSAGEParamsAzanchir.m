function SAGEParams = SetSAGEParamsAzanchir(screen_type)

if ~isempty(regexp(screen_type,'non_olympiad_azanchir_housing_CS_20120204','once')),
  
  SAGEParams = {'screen_type','non_olympiad_azanchir',...
    'line_name','EXT_CantonS_*',...
    'effector','NoEffector_0_9999',...
    'handling_protocol',{'HP_flybowl_v006p9.xls','HP_flybowl_v007p0.xls'},...
    'protocol',{'EP_flybowl_v011p1.xls','EP_flybowl_v011p2.xls'}};

elseif ~isempty(regexp(screen_type,'non_olympiad_azanchir_mating_galit_CS_20120211','once')),
  %SAGEParams = {'screen_type','non_olympiad_azanchir_mating_galit_CS_20120211'};
  SAGEParams = {'line_name','EXT_CantonS_*','effector','NoEffector_0_9999',...
    'handling_protocol',{'HP_flybowl_v007p1.xls','HP_flybowl_v007p2.xls','HP_flybowl_v007p3.xls',...
    'HP_flybowl_v007p6.xls','HP_flybowl_v007p7.xls'},...
    'protocol','EP_flybowl_v011p3.xls'};
elseif ~isempty(regexp(screen_type,'non_olympiad_azanchir_nicotine_mathias_berlin_20120211','once')),
  SAGEParams = {'screen_type','non_olympiad_azanchir',...
    'line_name',{'EXT_Berlin_1220272','EXT_CantonS_1101243'},...
    'effector','NoEffector_0_9999',...
    'handling_protocol',{'HP_flybowl_v007p4.xls','HP_flybowl_v007p5.xls'},...
    'protocol','EP_flybowl_v011p4.xls'};
elseif ~isempty(regexp(screen_type,'non_olympiad_azanchir_housing_CS_20120225','once')),
  SAGEParams = {'screen_type',screen_type,...
    'line_name','EXT_CantonS_1220002'};
else
  SAGEParams = {'screen_type',screen_type};
end