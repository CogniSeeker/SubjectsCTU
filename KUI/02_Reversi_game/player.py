import copy
import time

weight_matrix = [
    # weight of positions on boards 6x6, 8x8, 10x10
    [[90, 0, 30, 30, 0, 90],
     [0, -10, 8, 8, -10, 0],
     [30, 8, 15, 15, 8, 30],
     [30, 8, 15, 15, 8, 30],
     [0, -10, 8, 8, -10, 0],
     [90, 0, 30, 30, 0, 90]
     ],
    [[130, -10, 30, 15, 15, 30, -10, 130],
     [-10, -30, 5, 5, 5, 5, -30, -10],
     [30, 5, 25, 13, 13, 25, 5, 30],
     [15, 5, 13, 13, 13, 13, 5, 15],
     [15, 5, 13, 13, 13, 13, 5, 15],
     [30, 5, 25, 13, 13, 25, 5, 30],
     [-10, -30, 5, 5, 5, 5, -30, -10],
     [130, -10, 30, 15, 15, 30, -10, 130]
     ],
    [[130, -10, 30, 15, 15, 15, 15, 30, -10, 130],
     [-10, -30, 5, 5, 5, 5, 5, 5, -30, -10],
     [30, 5, 25, 13, 13, 13, 13, 25, 5, 30],
     [15, 5, 13, 13, 13, 13, 13, 13, 5, 15],
     [15, 5, 13, 13, 13, 13, 13, 13, 5, 15],
     [15, 5, 13, 13, 13, 13, 13, 13, 5, 15],
     [15, 5, 13, 13, 13, 13, 13, 13, 5, 15],
     [30, 5, 25, 13, 13, 13, 13, 25, 5, 30],
     [-10, -30, 5, 5, 5, 5, 5, 5, -30, -10],
     [130, -10, 30, 15, 15, 15, 15, 30, -10, 130]
     ]
]  

class MyPlayer():
    '''
    Minimax with adaptive depth, a-b prouning and spec evaluation
    '''
    
    def __init__(self, my_color,opponent_color, board_size=8):
        self.name = 'Oleharh' #my username
        self.my_color = my_color
        self.opponent_color = opponent_color
        self.board_size = board_size
        if self.board_size == 6:
            self.board_num = 0
        elif self.board_size == 8:
            self.board_num = 1
        elif self.board_size == 10:
            self.board_num = 2
               
    def move(self, board): 
        # set start time and start depth
        start_time = time.time()
        max_depth = 4
        if self.board_size == 10:
            max_depth = 3
        elif self.board_size == 6:
            max_depth = 5
        eval = 0
        best_move = None
        valid_moves = self.get_all_valid_moves(board, self.my_color)
        if valid_moves is None:
            return best_move
        if len(valid_moves) == 1:
            return valid_moves[0]
        else:
            while True:
                # if algorithm scanned all possible moves ahead
                # or time has ended
                if max_depth >= self.board_size**2 or eval == "TIME IS UP":
                    return best_move
                # set start variables
                alpha = float('-inf')
                beta = float('inf')
                maxEval = float('-inf')
                # for every valid move find the minimax evaluation
                for move in valid_moves:
                    # create temp board and update it with a new move
                    tempBoard = copy.deepcopy(board)
                    self.play_move(move, self.my_color, tempBoard)
                    # evaluate current move on temp board
                    eval = self.minimax(
                        move, tempBoard, max_depth, alpha, beta, False, start_time)
                    if eval != "TIME IS UP":
                    # if move is better than previous then
                    # change it to the temp best move
                        if eval > maxEval:
                            maxEval = eval
                            temp_best_move = move
                    else:
                        # if minimax returned "TIME IS UP"
                        break
                # change the actual best move
                best_move = temp_best_move
                # go in deeper evaluation
                max_depth += 1
    
    def minimax(self, move, board, depth, alpha, beta, myPlayer, start_time):
        '''
        Run Minimax evaluation. It looks a few states ahead and returns
        max possiblevalue for my player and min for opponent in every
        state in a recursive way.
        '''
        current_time = time.time()
        if (current_time - start_time) >= 4.950:
            return "TIME IS UP"
        # if set depth was reached evaluate the board
        if depth == 0:
            return self.evaluate_board(board)
        if myPlayer:
            valid_moves = self.get_all_valid_moves(board, self.my_color)
            #set the worst possible evaluation for myPlayer
            maxEval = float('-inf')
            if valid_moves is None:
                return self.evaluate_board(board)
            for move in valid_moves:
                # create temp board and update it with a new move
                tempBoard = copy.deepcopy(board)
                self.play_move(move, self.my_color, tempBoard)
                #evaluate current move through reverse minimax
                eval = self.minimax(
                    move, tempBoard, depth-1, alpha, beta, False, start_time)
                if eval == "TIME IS UP":
                    return eval
                maxEval = max(maxEval, eval)
                #alpha-beta prouning
                alpha = max(alpha, eval)
                if beta <= alpha:
                    break
            return maxEval
        # same actions but in opponents case
        else:
            valid_moves = self.get_all_valid_moves(board, self.opponent_color)
            #set the worst possible evaluation for opponent
            minEval = float('inf')
            if valid_moves is None:
                return self.evaluate_board(board)
            for move in valid_moves:
                tempBoard = copy.deepcopy(board)
                self.play_move(move, self.opponent_color, tempBoard)
                eval = self.minimax(
                    move, tempBoard, depth-1, alpha, beta, True, start_time)
                if eval == "TIME IS UP":
                    return eval
                minEval = min(minEval, eval)
                beta = min(beta, eval)
                if beta <= alpha:
                    break
            return minEval
    
    def evaluate_board(self, board):
        '''
        Evaluate current state on the board. 
        It uses weight of position and num of stones.
        The bigger eval is. the better situation is for player.
        The smaller eval is, the better situation is for opponent.
        '''
        score_positional = 0
        stones = {
                "my_player": 0,
                "opponent": 0
        }
        for x in range(self.board_size):
            for y in range(self.board_size):
                if board[x][y] == self.my_color:
                    score_positional += weight_matrix[self.board_num][x][y]
                    stones["my_player"] += 1
                elif board[x][y] == self.opponent_color:
                    score_positional -= weight_matrix[self.board_num][x][y]
                    stones["opponent"] += 1
        score_stones = stones["my_player"] - stones["opponent"]
        # coefficients for scores
        coef_stones = 0.5
        coef_position = 1
        if self.board_size == 6:
            coef_stones = 0
        score = coef_position*score_positional + coef_stones*score_stones
        return score
    
    def play_move(self, move, players_color, board):
        '''
        :param move: position where the move is made [x,y]
        :param player: player that made the move
        '''
        board[move[0]][move[1]] = players_color
        dx = [-1,-1,-1,0,1,1,1,0]
        dy = [-1,0,1,1,1,0,-1,-1]
        for i in range(len(dx)):
            if self.__confirm_direction(move, dx[i], dy[i], board, players_color):
                self.change_stones_in_direction(move, dx[i], dy[i], board, players_color)
    
    def __is_correct_move(self, move, board, players_color):
        dx = [-1, -1, -1, 0, 1, 1, 1, 0]
        dy = [-1, 0, 1, 1, 1, 0, -1, -1]
        for i in range(len(dx)):
            if self.__confirm_direction(move, dx[i], dy[i], board, players_color):
                return True, 
        return False

    def __confirm_direction(self, move, dx, dy, board, players_color):
        if players_color == self.my_color:
            opponents_color = self.opponent_color
        else:
            opponents_color = self.my_color
        posx = move[0]+dx
        posy = move[1]+dy
        if ((posx >= 0) and (posx < self.board_size) and
            (posy >= 0) and (posy < self.board_size)):
            if board[posx][posy] == opponents_color:
                while ((posx >= 0) and (posx < self.board_size) and
                       (posy >= 0) and (posy <self.board_size)):
                    posx += dx
                    posy += dy
                    if ((posx >= 0) and (posx < self.board_size) and
                        (posy >= 0) and (posy < self.board_size)):
                        # if tile is empty
                        if board[posx][posy] == -1:
                            return False
                        if board[posx][posy] == players_color:
                            return True
        return False

    def get_all_valid_moves(self, board, players_color):
        valid_moves = []
        for x in range(self.board_size):
            for y in range(self.board_size):
                if ((board[x][y] == -1) and
                        self.__is_correct_move([x, y], board, players_color)):
                    valid_moves.append( (x, y) )

        if len(valid_moves) <= 0:
            # No possible move
            return None
        # sort moves taking into account their weight on the board
        valid_moves = sorted(valid_moves, key=lambda move:
            weight_matrix[self.board_num][move[0]][move[1]], reverse=True)
        return valid_moves
        
    
    def change_stones_in_direction(self, move, dx, dy, board, players_color):
        posx = move[0]+dx
        posy = move[1]+dy
        while (not(board[posx][posy] == players_color)):
            board[posx][posy] = players_color
            posx += dx
            posy += dy