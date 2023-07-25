import sys
import copy

a = []

# To test:
# take 06_tic_tac_toe.txt from test_data_input folder
 
f = open(sys.argv[1], 'r')
for line in f:
    a.append(list(map(str, line.split())))

mat = copy.deepcopy(a)

M, N = len(mat), len(mat[0])

# change values of matix symbols into numbers
for i in range(len(mat)):       
    for j in range(len(mat[i])):
        if mat[i][j] == 'o':
            mat[i][j] = 5
        elif mat[i][j] == 'x':
            mat[i][j] = 1
        else:
            mat[i][j] = 0
            
 #return 1 or 5
def check_move(mat):       
    countX = 0
    countO = 0
    for i in range(M):
        countX += mat[i].count(1)
        countO += mat[i].count(5)
    if countX == countO:
        move = 5
    elif countX == countO - 1:
        move = 1
    return move
player = check_move(mat)     

def inside(x, y):
    if x < 0 or x >= M:
        return False
    if y < 0 or y >= N:
        return False
    return True    

global c
c = True   # counter number of outputs

def find__sequenceBetter(mat):
    count = 0
    array = []
    i = 0
    j = 0
    def find_vertical(mat, i, j):
        global c
        k = 1
        count = 0
        while inside(i+k, j) and mat[i+k][j] == player:
            count += 1
            k += 1
            if count == 4 and c:
                print( i, j)
                c = False
                
        k = 1
        while inside(i-k, j) and mat[i-k][j] == player:
            count += 1
            k += 1
            if count == 4 and c:
                print(i, j) 
                c = False
    
    def find_horizontal(mat, i, j):
        global c
        k = 1
        count = 0
        while inside(i, j+k) and mat[i][j+k] == player:
            count += 1
            k += 1
            if count == 4 and c:
                print(i, j) 
                c = False
        k = 1
        while inside(i, j-k) and mat[i][j-k] == player:
            count += 1
            k += 1
            if count == 4 and c:
                print(i, j) 
                c = False
                
    def find_diagonalR(mat, i, j):
        global c
        k = 1
        count = 0
        while inside(i+k, j+k) and mat[i+k][j+k] == player:
            count += 1
            k += 1
            if count == 4 and c:
                print(i, j) 
                c = False
                
        k = 1
        while inside(i-k, j-k) and mat[i-k][j-k] == player:
            count += 1
            k += 1
            if count == 4 and c:
                print(i, j) 
                c = False
    
    def find_diagonalL(mat, i, j):
        global c
        k = 1
        count = 0
        while inside(i+k, j-k) and mat[i+k][j-k] == player:
            count += 1
            k += 1
            if count == 4 and c:
                print(i, j) 
                c = False
                
        k = 1
        while inside(i-k, j+k) and mat[i-k][j+k] == player:
            count += 1
            k += 1
            if count == 4 and c:
                print(i, j) 
                c = False
                    
    while i < M:
        while j < N:
            if mat[i][j] == 0:
                # check every neighboor of element in matix
                for n_i, n_j in [(i-1, j), (i+1, j), (i, j-1), (i, j+1),
                                (i+1, j+1), (i+1, j-1), (i-1, j-1), (i-1, j+1)]:       
                    if inside(n_i, n_j) and mat[n_i][n_j] == player:
                        if (n_i == (i-1) or n_i == (i+1)) and n_j ==  j:
                            #push search vertical 
                            find_vertical(mat, i, j)
                            #print("push search vertical", i, j, n_i, n_j)
                        if n_i ==  i and (n_j == (j-1) or n_j == (j+1)):
                            #push search horizontal
                            find_horizontal(mat, i, j)
                            #print("push search horizontal", i, j, n_i, n_j)
                        if (n_i == i-1 and n_j == j-1) or (n_i == i+1 and n_j == j+1):
                            #push search diagonal
                            find_diagonalR(mat, i, j)
                            #print("push search diagonalR", i, j, n_i, n_j)
                        if (n_i == i-1 and n_j == j+1) or (n_i == i+1 and n_j == j-1):
                            #push search diagonalL
                            find_diagonalL(mat, i, j)
                            #print("push search diagonalL", i, j, n_i, n_j) 
                           
            j += 1
        j = 0
        i += 1               
            
find__sequenceBetter(mat)  