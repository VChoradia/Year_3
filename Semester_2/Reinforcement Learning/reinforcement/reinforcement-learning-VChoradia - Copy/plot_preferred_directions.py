import matplotlib.pyplot as plt
from gridworld_env import GridWorld
from utils import get_grid
from RLagent import RLagent
import numpy as np

def plot_preferred_movement_direction(agent: RLagent, env: GridWorld, title: str):

    direction_symbols = ['↑', '→', '↓', '←']

    # Extracting env features
    shape_of_grid = env.get_gridshape()
    locations_of_lava = env.get_lava_loc()
    locations_of_walls = env.get_walls_loc()
    locations_of_goals = env.get_goal_loc()
    starting_position = env.get_starting_loc()

    display_grid = np.full(shape_of_grid, '', dtype=object)

    for state_index in range(agent.q_table.shape[0]):
        optimal_action = np.argmax(agent.q_table[state_index, :])
        position = env.get_loc_from_state(state_index)
        
        # Only display actions for navigable locations
        if position not in locations_of_lava and position not in locations_of_walls and position not in locations_of_goals:
            display_grid[position[0], position[1]] = direction_symbols[optimal_action]

    fig, ax = plt.subplots(figsize=(6, 6))
    ax.matshow(np.zeros(shape_of_grid), cmap="Greys", alpha=0)

    # Annotating the grid
    for row in range(shape_of_grid[0]):
        for col in range(shape_of_grid[1]):
            action_symbol = display_grid[row, col]
            if action_symbol: 
                ax.text(col, row, action_symbol, ha='center', va='center', fontsize=13, color='black', weight='bold')
            position = (row, col)

            if position in locations_of_lava:
                ax.add_patch(plt.Rectangle((col - 0.5, row - 0.5), 1, 1, color='red'))
            elif position in locations_of_walls:
                ax.add_patch(plt.Rectangle((col - 0.5, row - 0.5), 1, 1, color='black'))
            elif position in locations_of_goals:
                ax.add_patch(plt.Rectangle((col - 0.5, row - 0.5), 1, 1, color='blue'))            
            elif position == starting_position:
                ax.add_patch(plt.Rectangle((col - 0.5, row - 0.5), 1, 1, color='yellow'))  

    # Configuring plot
    plt.title(f"{title}\n", fontsize=10)
    plt.xlim(-0.5, shape_of_grid[1] - 0.5)
    plt.ylim(shape_of_grid[0] - 0.5, -0.5)
    ax.xaxis.set_ticks_position('bottom')
    plt.show()