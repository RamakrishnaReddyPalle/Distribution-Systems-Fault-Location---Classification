% Define the model and fault block path
model = 'IEEE13NodeTestFeeder';   % Your model name
fault_block = 'fault_632';        % Name of the fault block (adjust this as necessary)

% Load the model if it's not already loaded
load_system(model);

% Full block path (replace fault block name if needed)
fault_block_path = [model, '/', fault_block];

% Get the dialog parameters of the block
dialog_params = get_param(fault_block_path, 'DialogParameters');

% Display the dialog parameters
disp('Dialog Parameters for the Three-Phase Fault Block:');
disp(dialog_params);
