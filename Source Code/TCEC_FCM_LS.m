%% TCEC-FCM-LS Algorithm for Total Causal Effect Calculation in Fuzzy Cognitive Maps
% This script implements the TCEC-FCM-LS algorithm as described in the paper:
% "Causal Effect Analysis in Large-Scale Fuzzy Cognitive Maps for Explainable Artificial Intelligence (XAI)"
% by Marios Tyrovolas, Nikolaos D. Kallimanis, and Chrysostomos Stylios.

clc
clear all
warning("off")
%% Synthetic Random FCM Generation

% Number of FCM concepts (e.g. 2 <= n <= 1000)
FCM_concepts = randsample([2:1000],1);

% Weight Matrix W
% Generate a random matrix with values in the range [-1, 1]
W = 2*rand(FCM_concepts) - 1;

% Set the diagonal elements to zero
W(1:FCM_concepts+1:end) = 0;

% Randomly choose a density in the range 10% to 100%, in steps of 10%
densityOptions = 0.1:0.1:1;
randomIndex = randi(length(densityOptions)); % Random index
density = densityOptions(randomIndex); % Select random density

% Randomly set some elements to zero based on the chosen density
mask = rand(FCM_concepts) < density;
W = W .* mask;

%% TCEC-FCM-LS Algorithm Implementation
% Implementation of the Total Causal Effect Calculation using Linear Search (TCEC-FCM-LS).
% This section calculates the total causal effect of each concept on the output concept in the FCM.

n = size(W, 1); % Number of FCM concepts
total_effects = zeros(n-1, 1); % Preallocating array for total effects

% Sorting weights and creating adjacency list for efficient traversal.

nonzero_weights = nonzeros(W);
[row, col] = find(W);
edges = [row, col];
[nonzero_weights,idx] = sort(nonzero_weights,'descend');
edges = edges(idx,:);

adj_list = cell(n, 1);
for i = 1:size(edges, 1)
    adj_list{edges(i, 1)}(end+1) = edges(i, 2);
end

output_node = n; % Assuming the last node is the output concept

tic % Start timer

% Main loop to calculate total causal effect.
for input_node = 1:(n-1)
    disp(input_node)
    % For each input node, initialize a copy of the FCM such that all vertexes are isolated
    W_copy_FCM = zeros(size(W));

    adjacencyList = cell(n, 1);
    
    added_weight = 0;

    for weight=1:height(nonzero_weights)
        added_weight = added_weight + 1;
        
        total_effects(input_node,1)=nonzero_weights(weight);
        
        %You add one by one weight (in descending order) to the FCM Copy
        W_copy_FCM(edges(weight,1),edges(weight,2)) = nonzero_weights(weight);
        
        %Create an adjacency list from the current weight matrix
        adjacencyList{edges(weight, 1)}(end+1) = edges(weight, 2);
        
        %Do BFS by adding this weight to check if you can get from the input node to the output node.
        traversed_from_input = bfs(adjacencyList, input_node, output_node);
        
        % Use the ismember function
        outputnodeExists = ismember(output_node, traversed_from_input);
        
        if outputnodeExists
            break;
        end
        

        % Check for the absence of causal paths. If the algorithm completes without interruption,
        % it implies no causal paths were found during the traversal of the vector containing all non-zero weights.
        if added_weight == height(nonzero_weights)
            total_effects(input_node,1) = 0;
        end
 
    end
    
end
toc % End timer
%% Graph Visualization
% Visualizing the FCM if the number of concepts is less than 20.
% This section creates a directed graph and plots it for a visual representation of the FCM.

if n < 20
    % Create a graph object from the matrix
    G = digraph(W);

    % Define a colormap to distinguish different input nodes' paths
    cmap = lines(n-1); % Creates a colormap with different colors

    % Define node names (optional)
    nodeNames = arrayfun(@(x) sprintf('C%d', x), 1:n, 'UniformOutput', false);
    G.Nodes.Name = nodeNames';

    % Plot the graph
    figure;
    plot(G, 'Layout', 'force', 'EdgeLabel', G.Edges.Weight);

    % Customize the plot as needed
    title('Fuzzy Cognitive Map');
    axis equal;
end
%% BFS to find nodes traversed from input concept Ci to terminal concept Cj

function traversed_nodes = bfs(adj_list, start_node, end_node)
    n = numel(adj_list);
    visited = false(1, n);
    
    queue = {start_node};
    visited(start_node) = true;
    
    while ~isempty(queue)
        current_node = queue{1};
        queue(1) = [];
        
        % Stop if current_node is the end node
        if current_node == end_node
            break;
        end
        
        % Add unvisited neighbors to queue
        for next_node = adj_list{current_node}
            if ~visited(next_node)
                visited(next_node) = true;
                queue{end+1} = next_node;
            end
        end
    end
    
    % Return all visited nodes up to and including the target node
    traversed_nodes = find(visited);
end
