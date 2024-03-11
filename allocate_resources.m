function allocated_resources = allocate_resources(List_A, R_reserved, R)
% Allocate resources to the tasks in List_A using the reserved resources in R_reserved


allocated_resources = cell(size(R));

% Initialize the allocated resources with the reserved resources
for i = 1:length(R_reserved)
    if ~isempty(R_reserved{i})
        allocated_resources{i} = R_reserved{i};
    end
end

% Allocate the remaining resources to the tasks in List_A
for i = 1:length(List_A)
    for j = 1:length(List_A{i})
        R_k = List_A{i}(j);
        if ~isempty(R_k)
            if isempty(allocated_resources{find(R==R_k)})
                allocated_resources{find(R==R_k)} = R_k;
            else
                allocated_resources{find(R==R_k)} = union(allocated_resources{find(R==R_k)}, R_k);
            end
        end
    end
end
end
