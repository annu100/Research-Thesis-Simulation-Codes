U = 10; % Set of UEs in the network
N = 100; % Total number of transmission slots in the sensing window
M = 50; % Total number of frequency resources available for transmission
T = 1e-3; % Duration of each transmission slot
R = [5, 10, 20]; % Set of resource reservation intervals (RRI) known to all UEs
PDB = 10e-3; % Packet Delay Budget
min_RSRP_threshold = -110; % Minimum RSRP threshold for CSSR selection
RC_range = [5, 15]; % Range for re-selection counter
pKeep = 0.5; % Probability of resource keep

% Initialize reserved resources for all UEs
R_reserved = cell(U, length(R));
for i = 1:U
for j = 1:length(R)
R_reserved{i,j} = [];
end
end

% Loop through sensing window
for n = 1:N
% Channel Sensing phase: determine probable candidate resources based on decoding of 1st Stage SCI
candidate_resources_per_vehicle = cell(1,U);
for i = 1:U
    % Continuously sense and monitor RSSI and RSRP across all subchannels
measured_RSSI = zeros(1,M);
measured_RSRP = zeros(1,M);
for j = 1:M
% Sense RSSI and RSRP for subchannel j
measured_RSSI(j) = sense_RSSI(j);
measured_RSRP(j) = sense_RSRP(j);
end
    % Determine candidate resources with low interference from other vehicles
    candidate_resources = [];
    for j = 1:M
        % Check if subchannel j is not reserved by other vehicles
        if is_not_reserved_by_other_vehicle(j, R_reserved(:, :), R)
            % Check if RSRP of subchannel j is above minimum threshold
            if measured_RSRP(j) > min_RSRP_threshold
                % Add subchannel j to list of candidate resources for UE i
                candidate_resources = [candidate_resources j];
            end
        end
    end

    % Store candidate resources
    candidate_resources_per_vehicle{i} = candidate_resources;
end

% Selection of Candidate Resources phase: choose selection window and create List-A
List_A_per_vehicle = cell(1,U);
for i = 1:U
    % Choose selection window starting at T1 and ending at T1+PDB
    T1 = (n-1)*T;
    selection_window_start = T1;
    selection_window_end = T1 + PDB;

    % Identify CSSRs within selection window based on criteria (i) and (ii)
    CSSRs = [];
    for j = candidate_resources_per_vehicle{i}
        % Check if subchannel j falls within selection window
        if (j-1)*T >= selection_window_start && j*T <= selection_window_end
            % Add subchannel j to list of candidate resources if it meets criteria (i) and (ii)
            if measured_RSRP(j) < min_RSRP_threshold && is_not_reserved_by_other_vehicle(j, R_reserved(:, :), R)
                CSSRs = [CSSRs j];
            end
        end
    end

    % If size of List-A is less than 20% of total CSSRs, repeat criteria (ii) with increased RSRP threshold
    List_A = [];
    while length(List_A) < 0.2*length(CSSRs)
       % Increase RSRP threshold
         min_RSRP_threshold = min_RSRP_threshold + delta_RSRP_threshold;
             % Reset List-A and repeat criteria (ii) with increased RSRP threshold
    List_A = [];
    for j = CSSRs
        % Check if RSRP of subchannel j is above increased threshold
        if measured_RSRP(j) > min_RSRP_threshold
            % Add subchannel j to List-A
            List_A = [List_A j];
        end
    end
end

% Store List-A for UE i
List_A_per_vehicle{i} = List_A;
end

% Selection of Final Resource phase: choose subchannel with highest RSRP from List-A for each UE
R_final = zeros(U,1);
for i = 1:U
% Initialize maximum RSRP and chosen subchannel
max_RSRP = -inf;
chosen_subchannel = 0;
% Check RSRP of each subchannel in UE i's List-A
for j = List_A_per_vehicle{i}
    if measured_RSRP(j) > max_RSRP
        % Update maximum RSRP and chosen subchannel if RSRP of subchannel j is greater than current maximum
        max_RSRP = measured_RSRP(j);
        chosen_subchannel = j;
    end
end

% Store chosen subchannel as final resource for UE i
R_final(i) = chosen_subchannel;
end

% Return final resource allocation
R_allocated = zeros(U,M);
for i = 1:U
R_allocated(i,R_final(i)) = 1;
end

end
function rssi = sense_RSSI(j)
% Function to sense RSSI for subchannel j
% Input: j - subchannel number
% Output: rssi - RSSI for subchannel j
% Note: This function can be implemented using a suitable wireless transceiver hardware
%       or simulated using a wireless channel model

% Dummy implementation: return a random RSSI value between -100 dBm and -40 dBm
rssi = -100 + (rand * 60);
end
function rsrp = sense_RSRP(j)
% Function to sense RSRP for subchannel j
% Input: j - subchannel number
% Output: rsrp - RSRP for subchannel j
% Note: This function can be implemented using a suitable wireless transceiver hardware
%       or simulated using a wireless channel model

% Dummy implementation: return a random RSRP value between -90 dBm and -60 dBm
rsrp = -90 + (rand * 30);
end
function is_reserved = is_not_reserved_by_other_vehicle(j, R_reserved, R)
% Function to check whether a given subchannel j is reserved by any other vehicle
% Input: j - subchannel number
%        R_reserved - matrix of reserved resources for all UEs
%        R - set of resource reservation intervals known to all UEs
% Output: is_reserved - boolean value indicating whether subchannel j is reserved by any other vehicle

is_reserved = false;
for k = 1:size(R_reserved, 1)
    for l = 1:length(R)
        rri = R(l);
        if ~isempty(R_reserved{k, l}) && any(R_reserved{k, l} == j) && mod(k-1, rri/T) == 0
            is_reserved = true;
            return;
        end
    end
end
end
