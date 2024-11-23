% Fault Locations and Types
fault_locations = {'632', '633', '634', '645', '646', '671', '611', '684', '692', '675', '652', '680'};
fault_types = {'AB', 'BC', 'AC', 'AG', 'BG', 'CG', 'ABC', 'ABG', 'BCG', 'ACG', 'ABCG', 'NoFault'};


% Fault Type Configurations
fault_configuration = containers.Map;
fault_configuration('AG')   = {'on', 'off', 'off', 'on'};    % Phase A + Ground
fault_configuration('BG')   = {'off', 'on', 'off', 'on'};    % Phase B + Ground
fault_configuration('CG')   = {'off', 'off', 'on', 'on'};    % Phase C + Ground
fault_configuration('AB')   = {'on', 'on', 'off', 'off'};    % Phase A + B
fault_configuration('BC')   = {'off', 'on', 'on', 'off'};    % Phase B + C
fault_configuration('AC')   = {'on', 'off', 'on', 'off'};    % Phase A + C
fault_configuration('ABC')  = {'on', 'on', 'on', 'off'};     % Three-phase
fault_configuration('ABG')  = {'on', 'on', 'off', 'on'};     % Phase A + B + Ground
fault_configuration('BCG')  = {'off', 'on', 'on', 'on'};     % Phase B + C + Ground
fault_configuration('ACG')  = {'on', 'off', 'on', 'on'};     % Phase A + C + Ground
fault_configuration('ABCG') = {'on', 'on', 'on', 'on'};      % All Phases + Ground
fault_configuration('NoFault') = {'off', 'off', 'off', 'off'}; % No Fault


% Load Simulink Model
model = 'IEEE13NodeTestFeeder';
load_system(model);


% Simulation Parameters
sim_time = 3;                  % Total simulation time in seconds
fault_resistance = 0.01;       % Fault resistance (ohms)
ground_resistance = 0.01;      % Ground fault resistance (ohms)
fault_start_time = 0.5;        % Fault start time (seconds)
fault_end_time = 2;          % Fault end time (seconds)
fault_duration = (fault_end_time-fault_start_time)*10; % This variable is used for folder naming, hence 10


% Loop through each fault location and type
for i = 1:length(fault_locations)
    for j = 1:length(fault_types)
        
        % Fetch fault configuration for the current type
        fault_setting = fault_configuration(fault_types{j});
        fault_block_path = sprintf('%s/fault_%s', model, fault_locations{i});
        
        % Configure the fault block parameters
        set_param(fault_block_path, 'FaultA', fault_setting{1});
        set_param(fault_block_path, 'FaultB', fault_setting{2});
        set_param(fault_block_path, 'FaultC', fault_setting{3});
        set_param(fault_block_path, 'GroundFault', fault_setting{4});
        set_param(fault_block_path, 'FaultResistance', num2str(fault_resistance));
        set_param(fault_block_path, 'GroundResistance', num2str(ground_resistance));
        set_param(fault_block_path, 'SwitchTimes', mat2str([fault_start_time, fault_end_time]));
        
        % Run simulation
        simOut = sim(model, 'StopTime', num2str(sim_time));
        
        % Retrieve simulation results
        time = simOut.tout;
        voltages_faulty = simOut.get(['Bus', fault_locations{i}, '_Voltages']);
        currents_faulty = simOut.get(['Bus', fault_locations{i}, '_Currents']);
        
        % Check for consistent data length
        min_length = min([length(time), length(voltages_faulty), length(currents_faulty)]);
        time = time(1:min_length);
        voltages_faulty = voltages_faulty(1:min_length, :);
        currents_faulty = currents_faulty(1:min_length, :);
        
        % Create table for the fault data
        fault_data = table(time, voltages_faulty, currents_faulty, ...
                           'VariableNames', {'Time', 'FaultyBusVoltages', 'FaultyBusCurrents'});
        
        % Add fault type and location to the table
        fault_data.FaultType = repmat(fault_types{j}, min_length, 1);
        fault_data.FaultLocation = repmat(fault_locations{i}, min_length, 1);
        
        % Save data to CSV
        folder_name = ['Fault_Data_', num2str(fault_duration), '/', fault_types{j}];
        if ~exist(folder_name, 'dir')
            mkdir(folder_name);
        end
        file_name = [folder_name, '/Bus_', fault_locations{i}, '.csv'];
        writetable(fault_data, file_name);
    end
end