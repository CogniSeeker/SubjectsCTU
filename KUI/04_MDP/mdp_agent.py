def find_policy_via_value_iteration(problem, discount_factor, epsilon):
    """
    Finds the optimal policy using the value iteration algorithm.
    """

    def evaluate_action_value(state, action, V):
        """
        Calculates the action value Q(s, a) for a given state, action, and value function.
        """
        return sum([prob * (problem.get_reward(s_prime) + discount_factor * V[s_prime])
                    for s_prime, prob in problem.get_next_states_and_probs(state, action)])

    def find_best_action(state, V):
        """
        Finds the best action for a given state based on the value function.
        """
        best_action, best_value = None, float('-inf')
        for action in problem.get_actions(state):
            action_value = evaluate_action_value(state, action, V)
            if action_value > best_value:
                best_value = action_value
                best_action = action
        return best_action

    states = problem.get_all_states()
    V = {state: 0 for state in states}
    policy = {state: None for state in states}

    # Value Iteration
    while True:
        delta = 0

        for state in states:
            if problem.is_terminal_state(state):
                continue

            old_value = V[state]
            V[state] = max([evaluate_action_value(state, action, V) for action in problem.get_actions(state)])
            delta = max(delta, abs(old_value - V[state]))

        if delta < epsilon:
            break

    # Extract the optimal policy from the value function
    for state in states:
        policy[state] = None if problem.is_terminal_state(state) else find_best_action(state, V)

    return policy

def find_policy_via_policy_iteration(problem, discount_factor, epsilon=1e-6):
    """
    Finds the optimal policy using the policy iteration algorithm.
    """

    def policy_evaluation(policy, V):
        """
        Evaluates the policy by calculating the value function.
        """
        while True:
            delta = 0
            for state in states:
                old_value = V[state]
                if not problem.is_terminal_state(state):
                    action = policy[state]
                    V[state] = sum([prob * (problem.get_reward(s_prime) + discount_factor * V[s_prime])
                                    for s_prime, prob in problem.get_next_states_and_probs(state, action)])
                delta = max(delta, abs(old_value - V[state]))
            if delta < epsilon:
                break
            
    def evaluate_action_value(state, action, V):
        """
        Calculates the action value Q(s, a) for a given state, action, and value function.
        """
        return sum([prob * (problem.get_reward(s_prime) + discount_factor * V[s_prime])
                    for s_prime, prob in problem.get_next_states_and_probs(state, action)])
        
    def find_best_action(state, V):
        """
        Finds the best action for a given state based on the value function.
        """
        best_action, best_value = None, float('-inf')
        for action in problem.get_actions(state):
            action_value = evaluate_action_value(state, action, V)
            if action_value > best_value:
                best_value = action_value
                best_action = action
        return best_action

    def policy_improvement(policy, V):
        """
        Improves the policy based on the value function.
        """
        policy_stable = True
        for state in states:
            if not problem.is_terminal_state(state):
                old_action = policy[state]
                policy[state] = find_best_action(state, V)
                if old_action != policy[state]:
                    policy_stable = False
        return policy_stable

    states = problem.get_all_states()
    policy = {state: list(problem.get_actions(state))[0] if problem.get_actions(state) else None for state in states}
    V = {state: 0 for state in states}

    while True:
        policy_evaluation(policy, V)
        policy_stable = policy_improvement(policy, V)
        if policy_stable:
            break

    return policy
