%% TCEC-FCM-BS Algorithm for Total Causal Effect Calculation in Fuzzy Cognitive Maps
% This script implements the TCEC-FCM-BS algorithm as described in the paper:
% "Causal Effect Analysis in Large-Scale Fuzzy Cognitive Maps for Explainable Artificial Intelligence (XAI)"
% by Marios Tyrovolas, Nikolaos D. Kallimanis, and Chrysostomos Stylios.

clc
clear all
warning("off")
%% Synthetic Random FCM Generation
% Generating a synthetic Fuzzy Cognitive Map (FCM) with a random number of concepts.

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
%% TCEC-FCM-BS Algorithm Implementation
% Implementation of the Total Causal Effect Calculation using Binary Search (TCEC-FCM-BS).
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
    
    mid_indexes_history = [];
    
    upperIndex = 1;
    lowerIndex = height(nonzero_weights);
    midIndex = 1;
    
    found_flag = false;
    
    while lowerIndex-upperIndex >= 1 
        
        mid_indexes_history = [mid_indexes_history, midIndex];

        adjacencyList = cell(n, 1);
        
        % Include weights in the FCM copy, starting from the first up 
        % to the current index.
        for weight = 1:midIndex
            
            W_copy_FCM(edges(weight,1),edges(weight,2)) = nonzero_weights(weight);

            %Create an adjacency list from the current weight matrix
            adjacencyList{edges(weight, 1)}(end+1) = edges(weight, 2);
        end
        
        %Do BFS to check if you can get from the input node Ci to the terminal node Cj.
        traversed_from_input = bfs(adjacencyList, input_node, output_node);
  
        % Use the ismember function
        outputnodeExists = ismember(output_node, traversed_from_input);
        
        if outputnodeExists
            lowerIndex = midIndex;
            found_flag = true;
            total_effects(input_node,1)=nonzero_weights(midIndex);
        else
            upperIndex = midIndex;
        end
        
        midIndex = (lowerIndex + upperIndex)/2;
        % The weight of the new current index will be examined in the next
        % iteration
        midIndex = round(midIndex,0); % Round to the nearest integer.
        
        % When the 'lowerIndex' and 'upperIndex' indexes have a difference of 1, 
        % an array with the single remaining weight is created. 
        % Exit loop after examining the last weight.
        if (lowerIndex-upperIndex == 1) && (ismember(midIndex, mid_indexes_history)==true)
            break
        end
     
    end
    
    % Check for the absence of causal paths.
    if found_flag == false
        total_effects(input_node,1) = 0;
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
%% BFS Algorithm
% Breadth-First Search (BFS) algorithm to find nodes traversed from an input concept to a terminal concept.

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