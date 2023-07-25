from sys import argv

# To test:
# take 09_horse.txt from test_data_input folder

# Read the 2D matrix representing the chessboard from the input file.
with open(argv[1], 'r') as f:
    field = [list(map(int, row.split())) for row in f]

class Moves:
    
    def __init__(self, field, horseId):
        self.horseId = horseId
        self.field = field

    def inside(self, i, j):
        # Check if the given position (i, j) is within the bounds of the chessboard.
        R = len(self.field)
        C = len(self.field[0])
        if i <= -1 or i >= R:
            return False
        if j <= -1 or j >= C:
            return False
        return True

    def find_goal(self):
        visited = []
        queue = [(self.horseId, [self.horseId])]
        while len(queue) > 0:
            horseId, way = queue.pop(0)
            i, j = horseId
            for n_i, n_j in [[i-2, j-1], [i-2, j+1], [i-1, j+2], [i+1, j+2],
                             [i+2, j+1], [i+2, j-1], [i+1, j-2], [i-1, j-2]]:
                if self.inside(n_i, n_j) and field[n_i][n_j] == 0 and [n_i, n_j] not in visited:
                    queue.append(([n_i, n_j], way + [[n_i, n_j]]))
                    visited.append([n_i, n_j])
                elif self.inside(n_i, n_j) and field[n_i][n_j] == 4:
                    # If the end position (4) is reached, print the path taken by the horse in (i, j) coords.
                    way += [[n_i, n_j]]
                    way.pop(0)
                    printWay = []
                    for i in way:
                        printWay.append(i[0])
                        printWay.append(i[1])
                    return printWay
        # If no valid path is found, print "NEEXISTUJE" and exit the program.
        print("NEEXISTUJE")
        exit()

for i in range(len(field)):
    for j in range(len(field[i])):
        if field[i][j] == 2:
            myStartId = [i, j]

# Print the sequence of moves taken by the horse in (i, j) coordinates.
print(' '.join(map(str, Moves(field, myStartId).find_goal())))
