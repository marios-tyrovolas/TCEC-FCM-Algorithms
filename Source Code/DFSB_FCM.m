%% DFSB-FCM Algorithm for Total Causal Effect Calculation in Fuzzy Cognitive Maps
% This script implements the DFSB-FCM algorithm as described in the paper:
% "Causal Effect Analysis in Large-Scale Fuzzy Cognitive Maps for Explainable Artificial Intelligence (XAI)"

clc
clear all
warning("off")
%% Synthetic Random FCM 

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

%% DFSB-FCM Algorithm Implementation
% Implementation of Depth-First Search with Backtracking (DFSB-FCM).
% This algorithm calculates the total causal effect of each concept in an FCM.

n = size(W, 1); % Number of FCM concepts
total_effects = zeros(n-1, 1); % Preallocating array for total effects

tic % Start timer

% Main loop to calculate total causal effect.
for i = 1:n-1
    disp(append("Input Concept ",num2str(i)))
    % Step 1: Find all causal paths from input concept i to the output
    % concept n and store the indirect effects for all paths of the current input concept
    
    initial_total_effect=-inf;
    
    total_effects(i) = find_all_paths_indirect_effects_and_total_effect(W, i, n,initial_total_effect);
    
    %If the total causal effect is -inf after DFSB it means
    %that there is no a causal relation between the two concepts
    if total_effects(i)==-inf
        total_effects(i)=0;
    end
    
end
toc % End timer
%% Graph Visualization

% If the number of FCM concepts are less than 30 nodes
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

%% DFSB Algorithm to Identify All Causal Paths in FCM
% Depth-First Search with Backtracking to identify all causal paths from a start node to a target node.

function total_effects = find_all_paths_indirect_effects_and_total_effect(W_local, start, target, initial_total_effect)
    visited = false(size(W_local, 1), 1);
    current_path = [];
    %indirect_effects_for_current_input = {};
    total_effects=initial_total_effect;
    % Initialize a counter for the number of identified causal paths
    
    total_effects = dfs(start, visited, current_path, total_effects);
    
    function [total_effects] = dfs(current, visited, current_path, total_effects)
        visited(current) = true;
        current_path(end+1) = current;
        total_effects=total_effects;
        
        % When the DFS algorithm has identified a new causal path
        if current == target
            I = min(W_local(sub2ind(size(W_local), current_path(1:end-1), current_path(2:end)))); % Vectorized min operation
            
            %Update the total effect on-the-fly
            total_effects = max(total_effects,I);
        else
            neighbors = find(W_local(current, :) ~= 0);
            for i = 1:length(neighbors)
                if ~visited(neighbors(i))
                    total_effects = dfs(neighbors(i), visited, current_path, total_effects);
                end
            end
        end
    end
    % At this point the DFS has identified all causal paths from the
    % current input concept to the output concept
end



