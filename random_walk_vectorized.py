# -*- coding: utf-8 -*-
"""
2D Random Walk Simulation (Vectorized)
Author: Enrique A. Alcantara
Description: Simulates a 2D random walk using NumPy vectorization for high performance.
"""

import numpy as np
import matplotlib.pyplot as plt

def simulate_random_walk(n_steps=50000):
    """
    Simulates a 2D random walk using NumPy vectorization.
    
    Args:
        n_steps (int): Number of steps to simulate.
    
    Returns:
        tuple: Arrays of x and y coordinates representing the trajectory.
    """
    # 1. Define possible moves (Up, Down, Left, Right)
    # [dx, dy]
    options = [
        [0, 1],   # Up
        [0, -1],  # Down
        [1, 0],   # Right
        [-1, 0]   # Left
    ]
    
    # 2. Generate random choices for all steps at once (Vectorization)
    # This avoids using slow Python loops for large N
    indices = np.random.choice(len(options), size=n_steps)
    steps = np.array(options)[indices]
    
    # 3. Calculate cumulative position (Trajectory)
    # np.cumsum integrates the steps: position[t] = sum(velocity[0..t])
    x = np.cumsum(steps[:, 0])
    y = np.cumsum(steps[:, 1])
    
    # Insert origin (0,0) at the start
    x = np.insert(x, 0, 0)
    y = np.insert(y, 0, 0)
    
    return x, y

# --- Execution Block ---
if __name__ == "__main__":
    # Configuration
    N = 50000
    
    print(f"Running simulation for {N} steps...")
    
    # Run simulation
    x_traj, y_traj = simulate_random_walk(N)
    
    # Visualization
    plt.figure(figsize=(10, 6))
    plt.plot(x_traj, y_traj, linewidth=0.5, alpha=0.8, color='#4c00b0') # Nu Purple ;)
    
    # Mark Start and End
    plt.plot(0, 0, 'go', label='Start (0,0)', markersize=8)
    plt.plot(x_traj[-1], y_traj[-1], 'ro', label='End', markersize=8)
    
    # Formatting
    plt.title(f"2D Random Walk Simulation (Vectorized)\n$n = {N}$ steps", fontsize=14)
    plt.xlabel("X Position")
    plt.ylabel("Y Position")
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.6)
    
    # Save the output for the README
    output_filename = "random_walk_results.png"
    plt.savefig(output_filename, dpi=100)
    print(f"Simulation complete. Graph saved to {output_filename}")
    
    plt.show()
