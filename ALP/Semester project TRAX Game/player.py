import draw as Drawer
import sys
import random
import copy
import base as Base

class Player(Base.BasePlayer):
    def __init__(self, board, name, color):
        Base.BasePlayer.__init__(self,board, name, color)        
        self.algorithmName = "No chance"
    global board
        
    def check_color(self, direction):
        if direction == [0,-1]:
            # My element match to LEFT side of another
            # first number - the side of my element that must match,
            # second number - the side of rival element
            return [2,0]   
        elif direction == [-1,0]:
            # My element match to TOP side of another
            return [3,1]
        elif direction == [0,1]:
            # My element match to LEFT side of another
            return [0,2]
        elif direction == [1,0]:
            # My element match to BOTTOM side of another
            return [1,3]
                        
    def check_possible_tiles(self, board, my_i, my_j):
        startTile = list("0000") #["0", "0", "0", "0"]
        if (Base.BasePlayer.inside(self, my_i, my_j-1) and board[my_i][my_j-1] != "none"):
            startTile[0] = board[my_i][my_j-1][2]
        if (Base.BasePlayer.inside(self, my_i-1, my_j) and board[my_i-1][my_j] != "none"):
            startTile[1] = board[my_i-1][my_j][3]
        if (Base.BasePlayer.inside(self, my_i, my_j+1) and board[my_i][my_j+1] != "none"):
            startTile[2] = board[my_i][my_j+1][0]   # "0" -> "d"
        if (Base.BasePlayer.inside(self, my_i+1, my_j) and board[my_i+1][my_j] != "none"):
            startTile[3] = board[my_i+1][my_j][1]
        #["0", "0", "d", "0"]
        tileIneed = list(startTile)
        #return tile that looks like ["l", "0", "d", "0"],
        # where "0" means "l" or "d"
        return tileIneed
    
    def find_valid_tiles(self, tileIneed):
        startTile = list(tileIneed)
        validTiles = []
        for tile in self.tiles:
            tile = list(tile)   #["l", "l", "d", "d"] and my ["0", "0", "d", "d"]
            for i in range(4):
                if tileIneed[i] == "0" and tile[i] == "d" and (tileIneed.count("d")+1) <= 2:
                    tileIneed[i] = "d"
                if tileIneed[i] == "0" and tile[i] == "l" and ((tileIneed.count("l")+1) <= 2):
                    tileIneed[i] = "l"
            if ''.join(tileIneed) in self.tiles and validTiles.count(''.join(tileIneed)) < 1:
                validTiles.append(''.join(tileIneed))
            tileIneed = list(startTile)
        return validTiles
    
    def forced(self, boardWithTile, my_i, my_j):
        R = len(self.board)
        C = len(self.board[0])
        #it is board with Tile that creates
        # a duty to launch forced move
        board = boardWithTile 
        placedTiles = []
        originTile = board[my_i][my_j]
        queue = [(my_i, my_j, originTile)]
        while len(queue) > 0:
            print("QUEUE: ", queue)
            def_i, def_j, def_tile = queue.pop(0)   # tile that was lately placed
            # left side
            new_i = def_i
            new_j = def_j-1
            if Base.BasePlayer.inside(self, new_i, new_j) and board[new_i][new_j] == "none":
                # validTile is in list form, with zeros
                validTile = self.check_possible_tiles(board, new_i, new_j)
                print("validtiles: ", self.check_possible_tiles(board, new_i, new_j))
                if validTile.count("d") == 2 or validTile.count("l") == 2:
                    # tile is in list form, without zeros, just tiles
                    tiles = self.find_valid_tiles(validTile)
                    print("Possible tiles: ", tiles)
                    tile = tiles[0]
                    placedTiles.append([new_i, new_j, ''.join(tile)])
                    queue.append((new_i, new_j, ''.join(tile)))
                    board[new_i][new_j] = ''.join(tile)
                    print("Left forced worked, tile: ", (new_i, new_j, ''.join(tile)))
                    print("Placed Tiles: ", placedTiles)
            # top side            
            new_i = def_i-1
            new_j = def_j          
            if Base.BasePlayer.inside(self, new_i, new_j) and board[new_i][new_j] == "none":
                validTile = self.check_possible_tiles(board, new_i, new_j)
                print("validtiles: ", self.check_possible_tiles(board, new_i, new_j))
                if validTile.count("d") == 2 or validTile.count("l") == 2:
                    tiles = self.find_valid_tiles(validTile)
                    print("Possible tiles: ", tiles)
                    tile = tiles[0]
                    placedTiles.append([new_i, new_j, ''.join(tile)])
                    queue.append((new_i, new_j, ''.join(tile)))
                    board[new_i][new_j] = ''.join(tile)
                    print("Top forced worked, tile: ", (new_i, new_j, ''.join(tile)))
                    print("Placed Tiles: ", placedTiles)
            # right side
            new_i = def_i
            new_j = def_j+1          
            if Base.BasePlayer.inside(self, new_i, new_j) and board[new_i][new_j] == "none":
                validTile = self.check_possible_tiles(board, new_i, new_j)
                print("validtiles: ", self.check_possible_tiles(board, new_i, new_j))
                if validTile.count("d") == 2 or validTile.count("l") == 2:
                    tiles = self.find_valid_tiles(validTile)
                    print("Possible tiles: ", tiles)
                    tile = tiles[0]
                    placedTiles.append([new_i, new_j, ''.join(tile)])
                    queue.append((new_i, new_j, ''.join(tile)))
                    board[new_i][new_j] = ''.join(tile)
                    print("Right forced worked, tile: ", (new_i, new_j, ''.join(tile)))
                    print("Placed Tiles: ", placedTiles)
            # bottom side
            new_i = def_i+1
            new_j = def_j          
            if Base.BasePlayer.inside(self, new_i, new_j) and board[new_i][new_j] == "none":
                validTile = self.check_possible_tiles(board, new_i, new_j)
                print("validtiles: ", self.check_possible_tiles(board, new_i, new_j))
                if validTile.count("d") == 2 or validTile.count("l") == 2:
                    tiles = self.find_valid_tiles(validTile)
                    print("Possible tiles: ", tiles)
                    tile = tiles[0]
                    placedTiles.append([new_i, new_j, ''.join(tile)])
                    queue.append((new_i, new_j, ''.join(tile)))
                    board[new_i][new_j] = ''.join(tile)
                    print("Bottom forced worked, tile: ", (new_i, new_j, ''.join(tile)))
                    print("Placed Tiles: ", placedTiles)
        for i in range(R):
            for j in range(C):
                if board[i][j] != "none":
                    i_r = i #i of rival
                    j_r = j #j of rival
                    validTiles = []
                    for direction in self.neighbors:
                        shift_i, shift_j = direction
                        my_i = i_r+shift_i
                        my_j = j_r+shift_j
                        if Base.BasePlayer.inside(self, my_i, my_j):
                            if board[my_i][my_j] == "none":
                                validTiles = self.find_valid_tiles(
                                    self.check_possible_tiles(board, my_i, my_j))
                                if validTiles == []:
                                    return ["BADMOVE"]
        return placedTiles
                           
    def move(self):
        board = copy.deepcopy(self.board)
        # return list of moves:
        # []  ... if the player cannot move
        # [ [r1,c1,piece1], [r2,c2,piece2] ... [rn,cn,piece2] ] - 
        # - place tiles to positions (r1,c1) .. (rn,cn)
        moves = []
        possibleMoves = []
        tileRival = ""
        R = len(self.board)
        C = len(self.board[0])  
        i = 0
        j = 0
        while i < R:
            while j < C:
                if board[i][j] != "none":
                    i_r = i #i of rival
                    j_r = j #j of rival
                    validTiles = []
                    tileRival = list(board[i_r][j_r])  # ex: ["d", "d", "l", "l"]
                    for direction in self.neighbors:
                        shift_i, shift_j = direction
                        my_i = i_r+shift_i
                        my_j = j_r+shift_j
                        if Base.BasePlayer.inside(self, my_i, my_j):
                            if board[my_i][my_j] == "none":
                                validTiles = self.find_valid_tiles(
                                    self.check_possible_tiles(board, my_i, my_j)) #  ['lldd', 'dldl']
                                if validTiles != []:
                                    tile = validTiles[random.randint(0, len(validTiles)-1)]
                                    board[my_i][my_j] = tile
                                    forcedBoard = copy.deepcopy(board)
                                    board[my_i][my_j] = "none"
                                    forcedMoves = self.forced(forcedBoard, my_i, my_j)
                                    if forcedMoves != [] and forcedMoves != ["BADMOVE"]:
                                        print("----FORCED MOVE!----")
                                        print("ForcedTiles: ", forcedMoves)
                                        possibleMoves.append([[my_i, my_j, tile]] + forcedMoves)
                                    elif forcedMoves == []:
                                        possibleMoves.append([[my_i, my_j, tile]])  
                j+=1
            j=0    
            i+=1
        if possibleMoves != []:
            print("possible_moves: ", possibleMoves)
            myMoves = possibleMoves[random.randint(0, len(possibleMoves)-1)]
            for move in myMoves:
                x, y, myTile = move
                board[x][y] = myTile
                moves.append(move)
            print("MOVES: ", moves)
            return moves
        else:
            return []
        
        


if __name__ == "__main__":

    boardRows = 10
    boardCols = boardRows
    board = [ ["none"]*boardCols for _ in range(boardRows) ]

    board[boardRows//2][boardCols//2] = ["lldd","dlld","ddll","lddl","dldl","ldld"][ random.randint(0,5) ]
    # board = [
    #     ['none', 'ddll', 'none', 'none', 'none', 'none', 'none'],
    #     ['none', 'lldd', 'ddll', 'lddl', 'dlld', 'none', 'none'],
    #     ['none', 'ldld', 'lldd', 'dlld', 'lddl', 'none', 'none'],
    #     ['none', 'ldld', 'lddl', 'ddll', 'lldd', 'dlld', 'none'],
    #     ['none', 'none', 'lldd', 'dldl', 'ddll', 'none', 'none'],
    #     ['none', 'none', 'none', 'none', 'none', 'none', 'none'],
    #     ['none', 'none', 'none', 'none', 'none', 'none', 'none']]
    d = Drawer.Drawer()

    p1 = Player(board,"player1", 'l'); 
    p2 = Player(board,"player2", 'd');

    # Test game. We assume that both player play correctly.
    # In Brute/Tournament case, more things will be checked
    # like types of variables, validity of moves, etc...

    idx = 0
    
    while True:

        #call player for his move
        rmove = p1.move()
        #write to board of both players
        for move in rmove:
            row,col, tile = move
            p1.board[row][col] = tile
            p2.board[row][col] = tile

        #make png with resulting board
        d.draw(p1.board, "move-{:04d}.png".format(idx))
        idx+=1

        if len(rmove) == 0:
            print("End of game")
            break
        p1,p2 = p2,p1  #switch players




