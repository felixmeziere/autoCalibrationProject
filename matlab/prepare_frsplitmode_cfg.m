clear 
close all

root = fileparts(fileparts(mfilename('fullpath')));
cfg_folder = fullfile(root,'config');
cfg = fullfile(cfg_folder,'210E_truncated.xml');
cfg_frmode = fullfile(cfg_folder,'210E_truncated_frmode.xml');
fr_demand_file = fullfile(cfg_folder,'210E_truncated_fr_demands.xml');
b = BeatsSimulation;
b.load_scenario(cfg);

link_ids = b.scenario_ptr.get_link_ids;
link_types = b.scenario_ptr.get_link_types;
is_source = b.scenario_ptr.is_source_link;
is_sink = b.scenario_ptr.is_sink_link;
demand_link = b.scenario_ptr.get_demandprofile_link_map;
link_id_begin_end = b.scenario_ptr.get_link_id_begin_end;

%% 1. extract offramp demands, put them in a separate file ................
fr_link_ids = link_ids(is_sink & ~strcmp(link_types,'Freeway'));
ind = ismember(demand_link(:,2),fr_link_ids);

% copy and cast
DemandSet = generate_mo('DemandSet',false);
DemandSet.ATTRIBUTE.id = 0;
DemandSet.ATTRIBUTE.project_id = 0;
DemandSet.demandProfile = b.scenario_ptr.scenario.DemandSet.demandProfile(ind);

for i=1:length(DemandSet.demandProfile)
    x = DemandSet.demandProfile(i).demand.CONTENT; 
    DemandSet.demandProfile(i).demand.CONTENT = writecommaformat(x,'%f');
end

% write them to a file
xml_write(fr_demand_file,DemandSet);

% delete them from scenario
b.scenario_ptr.scenario.DemandSet.demandProfile(ind) = [];

clear ind

%% 2. add actuators to all offramps .......................................

ActuatorSet = generate_mo('ActuatorSet',false);
ActuatorSet.ATTRIBUTE.id = 0;
ActuatorSet.ATTRIBUTE.project_id = 0;

a = generate_mo('actuator');
a.scenarioElement = generate_mo('scenarioElement');
a.scenarioElement.ATTRIBUTE.type = 'node';
a.actuator_type = generate_mo('actuator_type');
a.actuator_type.ATTRIBUTE.id = 0;
a.actuator_type.ATTRIBUTE.name = 'cms';

ActuatorSet.actuator = repmat(a,1,length(fr_link_ids));
for i=1:length(fr_link_ids)
    node_id = link_id_begin_end(link_id_begin_end(:,1)==fr_link_ids(i),2);
    ActuatorSet.actuator(i).ATTRIBUTE.id = i;
    ActuatorSet.actuator(i).scenarioElement.ATTRIBUTE.id = node_id;
end

b.scenario_ptr.scenario.ActuatorSet = ActuatorSet;

%% 3. add sr controller ...................................................

ControllerSet = generate_mo('ControllerSet',false);
ControllerSet.ATTRIBUTE.id = 0;
ControllerSet.ATTRIBUTE.project_id = 0;

c = generate_mo('controller');
c.ATTRIBUTE.type = 'SR_Generator';
c.ATTRIBUTE.name = 'SR_Generator';
c.ATTRIBUTE.id = 0;
c.ATTRIBUTE.dt = 0;
c.ATTRIBUTE.enabled = 'true';

p = generate_mo('parameter');
p.ATTRIBUTE.name = 'fr_flow_file';
p.ATTRIBUTE.value = fr_demand_file;
c.parameters.parameter = p;
clear p

target_actuator = repmat( struct('ATTRIBUTE',struct('id',nan)) , 1 , length(fr_link_ids) );
for i=1:length(fr_link_ids)
    target_actuator(i).ATTRIBUTE.id = ActuatorSet.actuator(i).ATTRIBUTE.id;
end

c.target_actuators.target_actuator = target_actuator;
ControllerSet.controller = c;
b.scenario_ptr.scenario.ControllerSet = ControllerSet;

clear c target_actuator ControllerSet

%% 4. remove all splits ...................................................
b.scenario_ptr.scenario = rmfield(b.scenario_ptr.scenario,'SplitRatioSet');

%% 5. save to xml .........................................................
b.scenario_ptr.save(cfg_frmode);



