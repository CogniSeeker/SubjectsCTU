import numpy as np
import time

def learn_policy(env):
    # Initialize environment, Q-table, and hyperparameters
    num_states = len(env.get_all_states())
    num_actions = env.action_space.n
    Q_table = np.zeros((num_states, num_states, num_actions))
    alpha = 0.1          # Learning rate
    gamma = 0.99         # Discount factor
    epsilon = 1.0        # Exploration rate
    epsilon_min = 0.01   # Minimum exploration rate
    epsilon_decay = 0.995
    max_time = 19
    start_time = time.time()

    # Train the agent using Q-learning
    while (time.time() - start_time) < max_time:
        state = env.reset()
        done = False

        while not done:
            # Choose action using epsilon-greedy strategy
            if np.random.rand() < epsilon:
                action = env.action_space.sample()
            else:
                action = np.argmax(Q_table[state[0], state[1], :])

            # Execute the action and observe the new state, reward, and done flag
            next_state, reward, done, _ = env.step(action)

            # Update the Q-table using the Q-learning formula
            Q_table[state[0], state[1], action] = Q_table[state[0], state[1], action] + \
                alpha * (reward + gamma * np.max(Q_table[next_state[0], next_state[1], :])
                - Q_table[state[0], state[1], action])

            state = next_state

        # Decay epsilon after each episode to decrease exploration over time
        epsilon = max(epsilon_min, epsilon_decay * epsilon)

    # Derive the optimal policy from the learned Q-table
    optimal_policy = {}
    for x in range(num_states):
        for y in range(num_states):
            state = (x, y)
            optimal_policy[state] = np.argmax(Q_table[x, y, :])

    return optimal_policy
