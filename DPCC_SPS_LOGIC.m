function [timeManagement, stationManagement, sinrManagement, Nreassign] = BRreassignment3GPPautonomous_withDPCC(timeManagement, stationManagement, positionManagement, sinrManagement, simParams, phyParams, appParams, outParams)
% Extended Sensing-based autonomous resource reselection algorithm (3GPP MODE 4) with Dynamic Probability-based Congestion Control (DPCC)

% Initialization as before
NbeaconsT = appParams.NbeaconsT;
NbeaconsF = appParams.NbeaconsF;
Nbeacons = NbeaconsT * NbeaconsF;
currentT = mod(timeManagement.elapsedTime_TTIs-1,NbeaconsT)+1;

% Active LTE vehicles
activeIDsCV2X = stationManagement.activeIDsCV2X;

% DPCC - New Step 1: Channel Sensing
% This should involve RSSI and RSRP measurement over time to detect candidate resources
channelSensingResults = channelSensingStep(stationManagement, sinrManagement);

% DPCC - New Step 2: Candidate Resource Identification
% Based on channel sensing, identify resources that can be potentially selected
[ListA, ListB] = candidateResourceIdentificationStep(channelSensingResults, simParams, stationManagement);

% Existing checks and procedures for resource reselection...

% DPCC - Integration in existing resource selection logic
% Use ListB for selecting the candidate resources in a more congestion-aware manner
[selectedResources, Nreassign] = candidateResourceSelectionStep(ListB, stationManagement, simParams);

% DPCC - New Step 3: Markov Chain State Update
% Update the Markov chain state for each vehicle based on the success or failure of their last transmission
stationManagement = markovChainStateUpdate(stationManagement, selectedResources);

% DPCC - New Step 4: Congestion Level Determination
% Determine the congestion level based on the current state of the network
congestionLevels = congestionLevelDetermination(stationManagement, selectedResources);

% DPCC - New Step 5: Probability of Resource Reservation
% Calculate the probability of reserving a resource based on the current congestion level
probReserveResource = probabilityOfResourceReservation(congestionLevels, selectedResources);

% DPCC - New Step 6: Resource Reselection
% Decide on resource reselection based on the congestion level and probability of resource reservation
stationManagement = resourceReselection(stationManagement, probReserveResource, selectedResources, Nreassign);

% Continue with the existing logic for HARQ allocation, new data indicator update, FD function calls, etc.
% ...
end

% The new DPCC-specific functions (channelSensingStep, candidateResourceIdentificationStep, candidateResourceSelectionStep,
% markovChainStateUpdate, congestionLevelDetermination, probabilityOfResourceReservation, resourceReselection)
% need to be implemented based on your DPCC approach, system model, and parameters.
%Channel Sensing Step
function channelSensingResults = channelSensingStep(stationManagement, sinrManagement)
    % Example function to simulate channel sensing based on RSSI/RSRP measurements
    % For simplicity, we return a matrix of sensed power levels for each vehicle and resource
    
    % Assuming sinrManagement contains RSSI/RSRP information for each vehicle and channel
    channelSensingResults = sinrManagement.sensedPowerLevels;
end
%2. Candidate Resource Identification Step
function [ListA, ListB] = candidateResourceIdentificationStep(channelSensingResults, simParams, stationManagement)
    % Identify candidate resources based on sensing results and minimum RSRP threshold
    
    threshold = simParams.minRSRPThreshold; % Minimum RSRP threshold for consideration
    ListA = channelSensingResults < threshold; % Boolean matrix indicating if resource is below threshold
    
    % Select top 20% of resources as ListB based on RSRP values, ignoring those above threshold
    numResources = numel(channelSensingResults);
    [sortedValues, ~] = sort(channelSensingResults(channelSensingResults < threshold), 'ascend');
    cutoffIndex = round(0.2 * length(sortedValues));
    cutoffValue = sortedValues(max(1, cutoffIndex)); % Ensure at least one resource is selected
    
    ListB = channelSensingResults < cutoffValue; % Boolean matrix for ListB
end
%3. Candidate Resource Selection Step
function [selectedResources, Nreassign] = candidateResourceSelectionStep(ListB, stationManagement, simParams)
    % Randomly select resources from ListB for each vehicle
    
    selectedResources = zeros(size(ListB)); % Initialize matrix of selected resources
    Nreassign = 0; % Counter for reassigned resources
    
    for v = 1:size(ListB, 1) % For each vehicle
        candidateResources = find(ListB(v, :)); % Find candidate resources for this vehicle
        if ~isempty(candidateResources)
            selectedIdx = randi(length(candidateResources)); % Randomly select an index
            selectedResources(v, candidateResources(selectedIdx)) = 1; % Mark resource as selected
            Nreassign = Nreassign + 1; % Increment reassign counter
        end
    end
end
%4. Markov Chain State Update
function stationManagement = markovChainStateUpdate(stationManagement, selectedResources)
    % Update Markov chain state based on transmission success or failure
    % This is a placeholder for the logic to update the Markov state, which would likely involve:
    % - Determining transmission success or failure based on some criteria
    % - Updating each vehicle's state based on these outcomes
    
    % Placeholder: Randomly update state to simulate varying transmission outcomes
    for v = 1:size(selectedResources, 1)
        if any(selectedResources(v, :))
            stationManagement.markovState(v) = rand > 0.5; % Randomly assign success (1) or failure (0)
        end
    end
end
%5. Congestion Level Determination
function congestionLevels = congestionLevelDetermination(stationManagement, selectedResources)
    % Determine congestion level based on transmission outcomes and resource usage
    % Placeholder: Compute a simple congestion metric based on the number of resources used
    
    totalResourcesUsed = sum(sum(selectedResources));
    totalVehicles = size(selectedResources, 1);
    
    % Example metric: ratio of used resources to total vehicles
    congestionLevels = totalResourcesUsed / totalVehicles;
end
%6. Probability of Resource Reservation
function probReserveResource = probabilityOfResourceReservation(congestionLevels, selectedResources)
    % Calculate the probability of reserving a resource based on congestion level
    % Placeholder: Inverse relationship between congestion level and reservation probability
    
    probReserveResource = 1 - min(congestionLevels / 100, 1); % Cap at 100 for example
end
%7. Resource Reselection
function stationManagement = resourceReselection(stationManagement, probReserveResource, selectedResources, Nreassign)
    % Decide on resource reselection based on the congestion level and probability of reservation
    % Placeholder: Randomly reselect resources based on reservation probability
    
    for v = 1:size(selectedResources, 1)
        if rand > probReserveResource
            % Placeholder for actual resource reselection logic
            stationManagement.reselectedResources(v) = randi(size(selectedResources, 2)); % Randomly reselect
        else
            % Keep current selection
            stationManagement.reselectedResources(v) = find(selectedResources(v, :));
        end
    end
end
