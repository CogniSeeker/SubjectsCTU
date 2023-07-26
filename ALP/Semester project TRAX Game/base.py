import copy

# !!!! DO NOT MODIFY THIS FILE !!!

class BasePlayer:
    def __init__(self,board, playerName, myColor):
        self.board = copy.deepcopy(board)  #game board, 2D array or [rows][cols]
        self.playerName = playerName       #name of the student in Brute and in Tournament
        self.myColor = myColor             #either 'l' or 'd' 
        self.algorithmName = "Trax master" #name of the algorithm, will be shown in tournament
        self.tournament = False            #true if player is run in tournament


        self.rivalColor = { 'l': 'd', 'd':'l' }   #rival's color is self.rivalColor[self.myColor]
        self.tiles = ["lldd","dlld","ddll","lddl","dldl","ldld"]  #valid names of the tiles
        self.neighbors = [ [0,-1],[-1,0],[0,1],[1,0] ]            #list of four-neighbors
        self.my2other = [2,3,0,1] #my side '0' points to 2, my side '1' points to 3 etc..


    def inside(self, r,c):
        """ return True if cell [r][c] is inside the board """
        return r >= 0 and r < len(self.board) and c >= 0 and c < len(self.board[0])

    def move(self):
        return []
