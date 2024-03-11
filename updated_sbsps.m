U = 10; % Set of UEs in the network
N = 100; % Total number of transmission slots in the sensing window
M = 50; % Total number of frequency resources available for transmission
T = 1e-3; % Duration of each transmission slot - 1 milisec
R = [5, 10, 20]; % Set of resource reservation intervals (RRI) known to all UEs
PDB = 10e-3; % Packet Delay Budget
min_RSRP_threshold = -110; % Minimum RSRP threshold for CSSR selection
RC_range = [5, 15]; % Range for re-selection counter
pKeep = 0.5; % Probability of resource keep
delta_RSRP_threshold = 10; % Increase in RSRP threshold for repeating criteria (ii)

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
            if (T >= selection_window_start) && (T < selection_window_end)
                % Check if RSRP of subchannel j is above minimum threshold
                if measured_RSRP(j) > min_RSRP_threshold
                    % Check if re-selection counter for subchannel j is within range
                    if is_within_RC_range(j, RC_range)
                        % Add subchannel j to list of CSSRs
                        CSSRs = [CSSRs j];
                    elseif (measured_RSRP(j) > (min_RSRP_threshold + delta_RSRP_threshold))
                        % Re-select subchannel j due to exceeding the threshold for repeating criteria (ii)
                        CSSRs = [CSSRs j];
                    end
                end
            end
        end
        % Sort CSSRs based on RSRP in descending order
        [~, sorted_indexes] = sort(measured_RSRP(CSSRs), 'descend');
        CSSRs_sorted = CSSRs(sorted_indexes);

        % Create List-A by selecting top k CSSRs based on pKeep probability
        k = round(length(CSSRs_sorted)*pKeep);
        List_A_per_vehicle{i} = CSSRs_sorted(1:k);
    end

    % Resource Allocation phase: allocate resources to UEs in List-A
    for i = 1:U
        % Allocate resources from List-A to UE i
        allocated_resources = allocate_resources(List_A_per_vehicle{i}, R_reserved(i,:), R);

        % Add allocated resources to R_reserved for UE i
        R_reserved(i, allocated_resources) = true;
    end
end

% Helper functions
function is_not_reserved = is_not_reserved_by_other_vehicle(subchannel_index, R_reserved, R)
is_not_reserved = true;
for i = 1:size(R_reserved,1)
for j = 1:length(R)
if ismember(subchannel_index, R_reserved(i,j)) && (j ~= find(R==R_reserved(i,j)(1)))
is_not_reserved = false;
return
end
end
end
end

function is_within_range = is_within_RC_range(subchannel_index, RC_range)
% Re-selection counter value for subchannel j is equal to the length of time since it was last selected
% Assume that it is selected in the previous transmission slot
% Thus, the re-selection counter for subchannel j is equal to n-1, where n is the current transmission slot number
n = length(RC_range);
reselection_counter = n - 1;
is_within_range = (reselection_counter >= RC_range(1)) && (reselection_counter <= RC_range(2));
end

