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
        end
    end
    % If no CSSRs found based on criteria (i) and (ii), repeat criteria (ii) with increased RSRP threshold
    if isempty(CSSRs)
        for j = candidate_resources_per_vehicle{i}
            % Check if subchannel j falls within selection window
            if (T >= selection_window_start) && (T < selection_window_end)
                % Check if RSRP of subchannel j is above minimum threshold plus delta threshold
                if measured_RSRP(j) > (min_RSRP_threshold + delta_RSRP_threshold)
                    % Check if re-selection counter for subchannel j is within range
                    if is_within_RC_range(j, RC_range)
                        % Add subchannel j to list of CSSRs
                        CSSRs = [CSSRs j];
                    end
                end
            end
        end
    end

    % Create List-A for UE i based on selected CSSRs and reserved resources
    List_A = [];
    for j = 1:length(CSSRs)
        % Check if subchannel j is not reserved by UE i or other UEs in RRI
        if is_not_reserved_by_self_or_others(CSSRs(j), R_reserved{i,:}, R_reserved(:, :), R)
            % Add subchannel j to List-A
            List_A = [List_A CSSRs(j)];
        end
    end
    % Randomly keep some of the reserved resources with probability pKeep
    for j = 1:length(R)
        if ~isempty(R_reserved{i,j})
            if rand() > pKeep
                R_reserved{i,j} = [];
            end
        end
    end
    % Store List-A for UE i
    List_A_per_vehicle{i} = List_A;
end
        end      
% Transmission phase: transmit data over resources in List-A
for i = 1:U
    % Transmit data over all resources in List-A for UE i
    for j = List_A_per_vehicle{i}
        % Transmit data over subchannel j
        transmit_data(j);
        % Reserve subchannel j for UE i for next RRI
        reserved_RRI_index = find(R >= mod(n-1,R(i)), 1);
        R_reserved{i,reserved_RRI_index} = [R_reserved{i,reserved_RRI_index} j];
    end
end
 end