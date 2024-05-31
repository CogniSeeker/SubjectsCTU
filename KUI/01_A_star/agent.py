import time
import kuimaze
import os
import math
 
class Agent(kuimaze.BaseAgent):
     
    def __init__(self, environment):
        self.environment = environment
 
    def heuristic(self, currentTile, goalTile):                                    # heuristic method to try to guess the remaining price to the goal tile from the current tile
        const = 1.3
        return const*math.sqrt((currentTile[0][0]-goalTile[0])**2 + (currentTile[0][1]- goalTile[1])**2)        # pythagorean theorem for finding the distance between current and goal tile (multiplied by the const number)
         
    def find_path(self):
 
        observation = self.environment.reset()     # necessary for maze initialization
        goal = observation[1][0:2]
        start = observation[0][0:2]                             # initial state (x, y)                                    
        visited = dict()                                        # visited tiles
        queue = [((start, 0.0), [(start, 0.0)], 0.0)]
        while len(queue) > 0:
            positionAndCost, path, cost = queue.pop(0)          # positionAndCost = (coordinates, price)
            position = positionAndCost[0]
            new_positions = self.environment.expand(position)         # [[(x1, y1), cost], [(x2, y2), cost], ... ]
            if position == goal:                                      # break the loop when the goal position is reached
                break
            else:
                for i in range(len(new_positions)): 
                    current = new_positions[i]                                                          # current tile
                    g_score = sum(tile[1] for tile in path) + current[1]                            # add price of tile to the whole price of our path
                    currentStr = str(current)                                                           # transform into str format to check whether it is "visited"
                    if currentStr not in visited:
                        h_score = self.heuristic(current, goal)   
                        f_score = g_score + h_score
                        cost = f_score
                        queue.append((current, path + [current], cost))
                        visited[currentStr] = positionAndCost
                    else:
                        continue
                queue = sorted(queue, key=lambda x: x[2])                   # sort queue from the cheapest to the most expensive path
                         
            # self.environment.render()               # show enviroment's GUI      
            # time.sleep(0.3)                         # sleep for demonstartion
             
        pathNode = [tile[0] for tile in path]         # create a list containing only the tiles
         
        if goal not in pathNode:
            return None
         
        return pathNode                            # return path as list of tuples in format: [(x1, y1), (x2, y2), ... ] if it exists
 
 
if __name__ == '__main__':
 
    MAP = 'maps/normal/normal9.bmp'
    # MAP = 'maps/easy/easy9.bmp'
    # MAP = 'maps/maps_difficult/maze50x50.bmp'
    MAP = os.path.join(os.path.dirname(os.path.abspath(__file__)), MAP)
    GRAD = (0, 0)
    SAVE_PATH = False
    SAVE_EPS = False
 
    env = kuimaze.InfEasyMaze(map_image=MAP, grad=GRAD)       # For using random map set: map_image=None
    agent = Agent(env) 
 
    path = agent.find_path()
    print(path)
    env.set_path(path)          # set path it should go from the init state to the goal state
    if SAVE_PATH:
        env.save_path()         # save path of agent to current directory
    if SAVE_EPS:
        env.save_eps()          # save rendered image to eps
    env.render(mode='human')
    time.sleep(3)