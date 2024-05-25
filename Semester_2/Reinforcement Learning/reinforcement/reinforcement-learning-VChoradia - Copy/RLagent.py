import numpy as np
from gridworld_env import GridWorld
import matplotlib.pyplot as plt

# Base class for RL agents
class RLagent:
    def __init__(self, env: GridWorld, policy_type='softmax', alpha=0.1, gamma=0.99, episodes=1000):
        self.env = env
        self.policy_type = policy_type
        self.alpha = alpha
        self.gamma = gamma
        self.episodes = episodes

    # Softmax function to compute probabilities
    def softmax(self, q_values, tau=1.0):
        exp_q = np.exp(q_values / tau - np.max(q_values / tau))  
        return exp_q / np.sum(exp_q)

    # Function to select actions based on policy type
    def select_action(self, q_table, state, epsilon=0.1, tau=1.0):
        if self.policy_type == 'epsilon-greedy':
            if np.random.rand() < epsilon:
                return np.random.randint(len(q_table[state]))
            else:
                return np.argmax(q_table[state])
        elif self.policy_type == 'softmax':
            action_probabilities = self.softmax(q_table[state], tau)
            return np.random.choice(np.arange(len(q_table[state])), p=action_probabilities)
        else:
            raise ValueError("Unsupported policy type")

# Q-learning agent
class QLearningAgent(RLagent):
    
    def __init__(self, env, policy_type='softmax', alpha=0.1, gamma=0.99, episodes=1000):
        super().__init__(env, policy_type, alpha, gamma, episodes)
        self.q_table = np.zeros((self.env.get_state_size(), self.env.get_action_size()))
    
    # Solve the environment using Q-learning algorithm
    def solve(self, epsilon=0.1, tau=1.0, seed=None):
        np.random.seed(seed)
        total_rewards = []
        total_steps = []

        for episode in range(self.episodes):
            state = self.env.reset()[1]
            done = False
            total_reward = 0
            steps = 0

            while not done:
                action = self.select_action(self.q_table, state, epsilon, tau)
                _, next_state, reward, done = self.env.step(action)
                
                if not self.env.is_terminal(next_state):
                    next_max = np.max(self.q_table[next_state, :])
                else: 
                    next_max = 0

                self.q_table[state, action] += self.alpha * (reward + self.gamma * next_max - self.q_table[state, action])

                state = next_state
                total_reward += reward
                steps += 1

            total_rewards.append(total_reward)
            total_steps.append(steps)

        policy = np.argmax(self.q_table, axis=1)
        return policy, total_rewards, total_steps

# SARSA agent
class SARSAAgent(RLagent):
    
    def __init__(self, env, policy_type='softmax', alpha=0.1, gamma=0.99, episodes=1000):
        super().__init__(env, policy_type, alpha, gamma, episodes)
        self.q_table = np.zeros((self.env.get_state_size(), self.env.get_action_size()))
    
    # Solve the environment using SARSA algorithm
    def solve(self, epsilon=0.1, tau=1.0, seed=None):
        np.random.seed(seed)
        total_rewards = []
        total_steps = []

        for episode in range(self.episodes):
            state = self.env.reset()[1]
            action = self.select_action(self.q_table, state, epsilon, tau)
            done = False
            total_reward = 0
            steps = 0

            while not done:
                _, next_state, reward, done = self.env.step(action)
                next_action = self.select_action(self.q_table, next_state, epsilon, tau)
                
                if not self.env.is_terminal(next_state):
                    td_target = reward + self.gamma * self.q_table[next_state, next_action]
                else:
                    td_target = reward
                    
                td_error = td_target - self.q_table[state, action]
                self.q_table[state, action] += self.alpha * td_error

                state, action = next_state, next_action
                total_reward += reward
                steps += 1

            total_rewards.append(total_reward)
            total_steps.append(steps)

        policy = np.argmax(self.q_table, axis=1)
        return policy, total_rewards, total_steps

# Q-learning with softmax and decaying tau
class QLearningSoftmaxDecayingTau(QLearningAgent):
    def __init__(self, env, tau_initial=1.0, tau_min=0.1, decay_rate=0.99, alpha=0.1, gamma=0.9, episodes=100):
        super().__init__(env, policy_type='softmax', alpha=alpha, gamma=gamma, episodes=episodes)
        self.q_table = np.zeros((self.env.get_state_size(), self.env.get_action_size()))
        self.tau_initial = tau_initial
        self.tau_min = tau_min
        self.decay_rate = decay_rate
        self.tau = tau_initial
        self.goal_1_visits = []
        self.goal_2_visits = []
        self.goal_1_rewards = []
        self.goal_2_rewards = []
        self.total_steps = []

    # Solve the environment with decaying tau
    def solve(self, seed=None):
        np.random.seed(seed)
        goal_visits = {goal: 0 for goal in self.env.get_goal_loc()}
        cumulative_rewards = {goal: 0 for goal in self.env.get_goal_loc()}

        for episode in range(self.episodes):
            t, state, reward, done = self.env.reset()
            total_reward = 0
            steps = 0

            while not done:
                action = self.select_action(self.q_table, state, tau=self.tau)
                t, next_state, reward, done = self.env.step(action)
                total_reward += reward
                steps += 1

                best_next_action = np.argmax(self.q_table[next_state])
                td_target = reward + self.gamma * self.q_table[next_state, best_next_action]
                td_error = td_target - self.q_table[state, action]
                self.q_table[state, action] += self.alpha * td_error

                state = next_state
            
            self.total_steps.append(steps)

            for goal in self.env.get_goal_loc():
                goal_state = self.env._get_state_from_loc(goal)
                if state == goal_state:
                    goal_visits[goal] += 1
                    cumulative_rewards[goal] += total_reward

            self.goal_1_visits.append(goal_visits[self.env.get_goal_loc()[0]])
            self.goal_2_visits.append(goal_visits[self.env.get_goal_loc()[1]])
            self.goal_1_rewards.append(cumulative_rewards[self.env.get_goal_loc()[0]])
            self.goal_2_rewards.append(cumulative_rewards[self.env.get_goal_loc()[1]])

            self.tau = max(self.tau_min, self.tau * self.decay_rate)
        
        return self.q_table, goal_visits, cumulative_rewards, self.total_steps

# SARSA with softmax and decaying tau
class SARSASoftmaxDecayingTau(SARSAAgent):
    def __init__(self, env, tau_initial=1.0, tau_min=0.1, decay_rate=0.99, alpha=0.1, gamma=0.9, episodes=100):
        super().__init__(env, policy_type='softmax', alpha=alpha, gamma=gamma, episodes=episodes)
        self.q_table = np.zeros((self.env.get_state_size(), self.env.get_action_size()))
        self.tau_initial = tau_initial
        self.tau_min = tau_min
        self.decay_rate = decay_rate
        self.tau = tau_initial
        self.goal_1_visits = []
        self.goal_2_visits = []
        self.goal_1_rewards = []
        self.goal_2_rewards = []
        self.total_steps = []

    # Solve the environment with decaying tau
    def solve(self, seed=None):
        np.random.seed(seed)
        goal_visits = {goal: 0 for goal in self.env.get_goal_loc()}
        cumulative_rewards = {goal: 0 for goal in self.env.get_goal_loc()}

        for episode in range(self.episodes):
            t, state, reward, done = self.env.reset()
            total_reward = 0
            steps = 0

            action = self.select_action(self.q_table, state, tau=self.tau)

            while not done:
                t, next_state, reward, done = self.env.step(action)
                total_reward += reward
                steps += 1
                next_action = self.select_action(self.q_table, next_state, tau=self.tau)

                td_target = reward + self.gamma * self.q_table[next_state, next_action]
                td_error = td_target - self.q_table[state, action]
                self.q_table[state, action] += self.alpha * td_error

                state, action = next_state, next_action
            
            self.total_steps.append(steps)
            
            for goal in self.env.get_goal_loc():
                goal_state = self.env._get_state_from_loc(goal)
                if state == goal_state:
                    goal_visits[goal] += 1
                    cumulative_rewards[goal] += total_reward

            self.goal_1_visits.append(goal_visits[self.env.get_goal_loc()[0]])
            self.goal_2_visits.append(goal_visits[self.env.get_goal_loc()[1]])
            self.goal_1_rewards.append(cumulative_rewards[self.env.get_goal_loc()[0]])
            self.goal_2_rewards.append(cumulative_rewards[self.env.get_goal_loc()[1]])

            self.tau = max(self.tau_min, self.tau * self.decay_rate)
        
        return self.q_table, goal_visits, cumulative_rewards, self.total_steps

# Q-learning with eligibility traces
class QLearningSoftmaxDecayingTauTraces(QLearningSoftmaxDecayingTau):
    def __init__(self, env, tau_initial=1.0, tau_min=0.1, decay_rate=0.99, alpha=0.1, gamma=0.9, lambda_trace=0.8, episodes=100):
        super().__init__(env, tau_initial, tau_min, decay_rate, alpha, gamma, episodes)
        self.lambda_trace = lambda_trace
        self.goal_1_visits = []
        self.goal_2_visits = []
        self.goal_1_rewards = []
        self.goal_2_rewards = []

    # Solve the environment with eligibility traces
    def solve(self, seed=None):
        np.random.seed(seed)
        self.e_table = np.zeros_like(self.q_table)
        goal_visits = {goal: 0 for goal in self.env.get_goal_loc()}
        cumulative_rewards = {goal: 0 for goal in self.env.get_goal_loc()}

        for episode in range(self.episodes):
            t, state, reward, done = self.env.reset()
            total_reward = 0
            steps = 0
            self.e_table.fill(0)  # Reset eligibility traces

            while not done:
                action = self.select_action(self.q_table, state, tau=self.tau)
                t, next_state, reward, done = self.env.step(action)
                total_reward += reward
                steps += 1

                best_next_action = np.argmax(self.q_table[next_state])
                td_target = reward + self.gamma * self.q_table[next_state, best_next_action]
                td_error = td_target - self.q_table[state, action]

                self.e_table *= self.gamma * self.lambda_trace
                self.e_table[state, action] += 1
                self.q_table += self.alpha * td_error * self.e_table

                state = next_state

            self.total_steps.append(steps)
            self.tau = max(self.tau_min, self.tau * self.decay_rate)

            for goal in self.env.get_goal_loc():
                goal_state = self.env._get_state_from_loc(goal)
                if state == goal_state:
                    goal_visits[goal] += 1
                    cumulative_rewards[goal] += total_reward

            self.goal_1_visits.append(goal_visits[self.env.get_goal_loc()[0]])
            self.goal_2_visits.append(goal_visits[self.env.get_goal_loc()[1]])
            self.goal_1_rewards.append(cumulative_rewards[self.env.get_goal_loc()[0]])
            self.goal_2_rewards.append(cumulative_rewards[self.env.get_goal_loc()[1]])

        return self.q_table, goal_visits, cumulative_rewards, self.total_steps

# SARSA with eligibility traces
class SARSASoftmaxDecayingTauTraces(SARSASoftmaxDecayingTau):
    def __init__(self, env, tau_initial=1.0, tau_min=0.1, decay_rate=0.99, alpha=0.1, gamma=0.9, lambda_trace=0.8, episodes=100):
        super().__init__(env, tau_initial, tau_min, decay_rate, alpha, gamma, episodes)
        self.lambda_trace = lambda_trace
        self.goal_1_visits = []
        self.goal_2_visits = []
        self.goal_1_rewards = []
        self.goal_2_rewards = []

    # Solve the environment with eligibility traces
    def solve(self, seed=None):
        np.random.seed(seed)
        self.e_table = np.zeros_like(self.q_table)
        goal_visits = {goal: 0 for goal in self.env.get_goal_loc()}
        cumulative_rewards = {goal: 0 for goal in self.env.get_goal_loc()}

        for episode in range(self.episodes):
            t, state, reward, done = self.env.reset()
            total_reward = 0
            steps = 0
            self.e_table.fill(0)  # Reset eligibility traces

            action = self.select_action(self.q_table, state, tau=self.tau)

            while not done:
                t, next_state, reward, done = self.env.step(action)
                total_reward += reward
                steps += 1
                next_action = self.select_action(self.q_table, next_state, tau=self.tau)

                td_target = reward + self.gamma * self.q_table[next_state, next_action]
                td_error = td_target - self.q_table[state, action]

                self.e_table *= self.gamma * self.lambda_trace
                self.e_table[state, action] += 1
                self.q_table += self.alpha * td_error * self.e_table

                state, action = next_state, next_action

            self.total_steps.append(steps)
            self.tau = max(self.tau_min, self.tau * self.decay_rate)

            for goal in self.env.get_goal_loc():
                goal_state = self.env._get_state_from_loc(goal)
                if state == goal_state:
                    goal_visits[goal] += 1
                    cumulative_rewards[goal] += total_reward

            self.goal_1_visits.append(goal_visits[self.env.get_goal_loc()[0]])
            self.goal_2_visits.append(goal_visits[self.env.get_goal_loc()[1]])
            self.goal_1_rewards.append(cumulative_rewards[self.env.get_goal_loc()[0]])
            self.goal_2_rewards.append(cumulative_rewards[self.env.get_goal_loc()[1]])

        return self.q_table, goal_visits, cumulative_rewards, self.total_steps

# Simple neural network for approximating Q-functions
class SimpleNeuralNetwork:
    """A simple neural network for approximating Q-functions with one hidden layer and ReLU activation."""
    def __init__(self, input_size, hidden_size, output_size, learning_rate=0.01):
        self.input_size = input_size
        self.hidden_size = hidden_size
        self.output_size = output_size
        self.learning_rate = learning_rate

        # Initialize weights with a more stable method (He initialization for ReLU)
        self.weights_input_to_hidden = np.random.randn(input_size, hidden_size) * np.sqrt(2. / input_size)
        self.weights_hidden_to_output = np.random.randn(hidden_size, output_size) * np.sqrt(2. / hidden_size)

    def relu(self, x):
        """ReLU activation function."""
        return np.maximum(0, x)

    def relu_derivative(self, x):
        """Derivative of ReLU activation function."""
        return (x > 0).astype(float)

    def predict(self, state):
        """Forward pass through the network using ReLU."""
        self.hidden_layer = self.relu(np.dot(state, self.weights_input_to_hidden))
        return np.dot(self.hidden_layer, self.weights_hidden_to_output)

    def update(self, state, target_f):
        """Backward pass with gradient descent update using ReLU."""
        predicted_f = self.predict(state)
        output_error = target_f - predicted_f
        hidden_error = np.dot(output_error, self.weights_hidden_to_output.T) * self.relu_derivative(self.hidden_layer)

        # Gradient clipping
        clip_value = 1  # You can adjust this threshold based on your specific needs
        np.clip(hidden_error, -clip_value, clip_value, out=hidden_error)

        # Gradient descent
        self.weights_hidden_to_output += self.learning_rate * np.dot(self.hidden_layer.T, output_error)
        self.weights_input_to_hidden += self.learning_rate * np.dot(state.T, hidden_error)

        # Debug information
        if np.any(np.isnan(self.weights_input_to_hidden)) or np.any(np.isnan(self.weights_hidden_to_output)):
            print("NaN detected in weights after update")

# Q-learning with ANN function approximation
class QLearningANN(QLearningSoftmaxDecayingTau):
    def __init__(self, env: GridWorld, tau_initial=1.0, tau_min=0.1, decay_rate=0.99, alpha=0.01, gamma=0.9, episodes=1000):
        super().__init__(env, tau_initial, tau_min, decay_rate, alpha, gamma, episodes)
        self.state_size = env.get_state_size()
        self.action_size = env.get_action_size()
        self.q_network = SimpleNeuralNetwork(self.state_size, 24, self.action_size, self.alpha)
        self.goal_1_visits = []
        self.goal_2_visits = []
        self.goal_1_rewards = []
        self.goal_2_rewards = []
        self.total_steps = 0 

    # Overriding softmax to work with neural network predictions
    def softmax(self, q_values, tau):
        """Compute softmax probabilities for choosing actions based on tau (temperature)."""
        q_adjusted = q_values - np.max(q_values)
        exp_q = np.exp(q_adjusted / tau)
        sum_exp_q = np.sum(exp_q, axis=1, keepdims=True)
        return exp_q / sum_exp_q

    # Choose action based on the current state using the neural network
    def choose_action(self, state):
        q_values = self.q_network.predict(state)
        if np.any(np.isnan(q_values)):
            raise ValueError("Q-values contain NaN before softmax")
        action_probs = self.softmax(q_values, self.tau)
        if np.any(np.isnan(action_probs)):
            raise ValueError("Softmax probabilities contain NaN")
        return np.random.choice(self.action_size, p=action_probs[0])

    # Solve the environment using Q-learning with ANN
    def solve(self, seed=None):
        np.random.seed(seed)
        goal_visits = {goal: 0 for goal in self.env.get_goal_loc()}
        cumulative_rewards = {goal: 0 for goal in self.env.get_goal_loc()}

        for episode in range(self.episodes):
            t, state, reward, done = self.env.reset()  # Here state should be scalar
            one_hot_state = np.eye(self.state_size)[state].reshape(1, -1)  # Convert to one-hot for network

            while not done:
                action = self.choose_action(one_hot_state)
                t, next_state, reward, done = self.env.step(action)
                next_one_hot_state = np.eye(self.state_size)[next_state].reshape(1, -1)  # Convert to one-hot for network

                # Update neural network with one-hot states
                best_next_action = np.argmax(self.q_network.predict(next_one_hot_state))
                td_target = reward + self.gamma * self.q_network.predict(next_one_hot_state)[0][best_next_action]
                target_f = self.q_network.predict(one_hot_state)
                target_f[0][action] = td_target
                self.q_network.update(one_hot_state, target_f)

                one_hot_state = next_one_hot_state  # Use one-hot version for next loop
                state = next_state  # Keep the scalar version for comparisons

            # Update metrics after state comparison
            for goal in self.env.get_goal_loc():
                goal_state = self.env._get_state_from_loc(goal)  # This should be a scalar
                if state == goal_state:
                    goal_visits[goal] += 1
                    cumulative_rewards[goal] += reward

            self.goal_1_visits.append(goal_visits[self.env.get_goal_loc()[0]])
            self.goal_2_visits.append(goal_visits[self.env.get_goal_loc()[1]])
            self.goal_1_rewards.append(cumulative_rewards[self.env.get_goal_loc()[0]])
            self.goal_2_rewards.append(cumulative_rewards[self.env.get_goal_loc()[1]])

            self.tau = max(self.tau_min, self.tau * self.decay_rate)
        
        return self.q_network, goal_visits, cumulative_rewards, self.total_steps

# SARSA with ANN function approximation
class SARSAANN(SARSASoftmaxDecayingTau):
    def __init__(self, env: GridWorld, tau_initial=1.0, tau_min=0.1, decay_rate=0.99, alpha=0.01, gamma=0.9, episodes=1000):
        super().__init__(env, tau_initial, tau_min, decay_rate, alpha, gamma, episodes)
        self.state_size = env.get_state_size()
        self.action_size = env.get_action_size()
        self.q_network = SimpleNeuralNetwork(self.state_size, 24, self.action_size, self.alpha)
        self.goal_1_visits = []
        self.goal_2_visits = []
        self.goal_1_rewards = []
        self.goal_2_rewards = []
        self.total_steps = 0 

    # Overriding softmax to work with neural network predictions
    def softmax(self, q_values, tau):
        """Compute softmax probabilities for choosing actions based on tau (temperature)."""
        q_adjusted = q_values - np.max(q_values)
        exp_q = np.exp(q_adjusted / tau)
        sum_exp_q = np.sum(exp_q, axis=1, keepdims=True)
        return exp_q / sum_exp_q

    # Choose action based on the current state using the neural network
    def choose_action(self, state):
        q_values = self.q_network.predict(state)
        if np.any(np.isnan(q_values)):
            raise ValueError("Q-values contain NaN before softmax")
        action_probs = self.softmax(q_values, self.tau)
        if np.any(np.isnan(action_probs)):
            raise ValueError("Softmax probabilities contain NaN")
        return np.random.choice(self.action_size, p=action_probs[0])

    # Solve the environment using SARSA with ANN
    def solve(self, seed=None):
        np.random.seed(seed)
        goal_visits = {goal: 0 for goal in self.env.get_goal_loc()}
        cumulative_rewards = {goal: 0 for goal in self.env.get_goal_loc()}

        for episode in range(self.episodes):
            t, state, reward, done = self.env.reset()
            one_hot_state = np.eye(self.state_size)[state].reshape(1, -1)  # Convert to one-hot for network
            action = self.choose_action(one_hot_state)

            while not done:
                t, next_state, reward, done = self.env.step(action)
                next_one_hot_state = np.eye(self.state_size)[next_state].reshape(1, -1)
                next_action = self.choose_action(next_one_hot_state)
                self.total_steps += 1 

                td_target = reward + self.gamma * self.q_network.predict(next_one_hot_state)[0][next_action]
                target_f = self.q_network.predict(one_hot_state)
                target_f[0][action] = td_target
                self.q_network.update(one_hot_state, target_f)

                one_hot_state = next_one_hot_state  # Use one-hot version for next loop
                state = next_state  # Keep the scalar version for comparisons
                action = next_action

            # Update cumulative metrics after loop when state comparison is needed
            for goal in self.env.get_goal_loc():
                goal_state = self.env._get_state_from_loc(goal)  # This should be a scalar
                if state == goal_state:
                    goal_visits[goal] += 1
                    cumulative_rewards[goal] += reward

            self.goal_1_visits.append(goal_visits[self.env.get_goal_loc()[0]])
            self.goal_2_visits.append(goal_visits[self.env.get_goal_loc()[1]])
            self.goal_1_rewards.append(cumulative_rewards[self.env.get_goal_loc()[0]])
            self.goal_2_rewards.append(cumulative_rewards[self.env.get_goal_loc()[1]])

            self.tau = max(self.tau_min, self.tau * self.decay_rate)
        
        return self.q_network, goal_visits, cumulative_rewards, self.total_steps
