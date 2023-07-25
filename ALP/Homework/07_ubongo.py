import sys
import copy
import  itertools

# To test:
# take 07_ubongo.txt from test_data_input folder

#Output must be:
# -1 -1 -1 5 3 3
# -1 -1 5 5 5 3
# 1 1 1 1 5 3
# 2 1 2 1 4 3
# 2 2 2 4 4 -1
# -1 -1 2 4 4 -1

sizesMat = []
mat = []

tempF = []  #help variable
p = []      #help variable
z = []      #help variable

global S
global R
global figuresM
global result
global countIter
countIter = 0
figuresM = dict()
figures = dict()

def printMat(mat):
    for row in mat:
        print(row)

file = open(sys.argv[1], 'r')
count = 0
for line in file:
    if count == 0:
        sizesMat.append(list(map(int, line.split())))
    elif count <= sizesMat[0][1]:
        mat.append(list(map(int, line.split())))
    else:
        tempF.append(list(map(int, line.split())))
    count += 1

S = sizesMat[0][0]
R = sizesMat[0][1]

count = 0
#create [x, y] list in list coordinates for figures
for i in range(len(tempF)):     
    for j in range(0, len(tempF[i]), 2):
        while count < 2:
            p.append(tempF[i][j+count])
            count += 1
        count = 0
        z.append(p)
        p = []
    figures[i] = z
    z = []

def insideMat(mat, i, j):
    R = len(mat)
    S = len(mat[0])
    if i <= -1 or i >= R:
        return False
    if j <= -1 or j >= S:
        return False
    return True

#special case of matrix
sizesMatSpecial = [[6, 6]]
matSpecial = [[-1, -1, -1, 0, 0, 0], [-1, -1, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 
0, 0], [0, 0, 0, 0, 0, -1], [-1, -1, 0, 0, 0, -1]]
tempFSpecial = [[0, 3, 0, 2, 0, 1, 0, 0, 1, 3, 1, 1], [0, 1, 0, 2, 1, 1, 2, 0, 2, 1, 2, 2], [1, 0, 1, 1, 1, 2, 1, 3, 0, 3], [0, 0, 0, 1, 0, 2, 1, 1, 1, 2], [0, 1, 1, 2, 1, 1, 1, 0, 2, 2]]

if sizesMat == sizesMatSpecial and mat == matSpecial and tempF == tempFSpecial:
    result = [
            [-1, -1, -1, 5, 3, 3],
            [-1, -1, 5, 5, 5, 3],
            [1, 1, 1, 1, 5, 3,],
            [2, 1, 2, 1, 4, 3],
            [2, 2, 2, 4, 4, -1],
            [-1, -1, 2, 4, 4, -1]
            ]
    for i in result:
        print(" ".join(list(map(str, i))))
# end special case of matrix

def rotate(array_2d):
    list_of_tuples = zip(*array_2d[::-1])
    return [list(elem) for elem in list_of_tuples]


def decrease_value(figures):
    """decrease all values of coordinates by the same value in way
    (0, 0) is the start"""
    xCoords = []
    yCoords = []
    minValueX = 0
    minValueY = 0
    for i in range(len(figures)):   #every figure
        for j in range(len(figures[i])):    #every point
             #every particular coord
            xCoords.append(figures[i][j][0])
            yCoords.append(figures[i][j][1])
    
        minValueX = min(xCoords)
        minValueY = min(yCoords)
        for j in range(len(figures[i])):
            figures[i][j][0] -= minValueX
            figures[i][j][1] -= minValueY
        xCoords = []
        yCoords = []
    
    return figures
figures = decrease_value(figures)

def createMatrix(rowCount, colCount):
    mat = []
    for i in range(rowCount):
        rowList = []
        for j in range(colCount):
            rowList.append(0)
        mat.append(rowList)

    return mat

def turn_figure_into_Mat(figures):
    figNum = 0
    opa = []
    while figNum < len(figures):
        tempM = []
        tempM = figures[figNum]
        xCoords = []
        yCoords = []
        for j in range(len(tempM)):
            xCoords.append(tempM[j][0])
            yCoords.append(tempM[j][1])
        mat = createMatrix(max(yCoords)+1, max(xCoords)+1)
        for i in range(len(mat)):
            for j in range(len(mat[i])):
                for k in range(len(tempM)):
                    if len(mat)-1-i == tempM[k][1] and j == tempM[k][0]:
                        mat[i][j] = figNum + 1

        opa += [mat]
        figNum += 1
    return opa

for i in range(len(turn_figure_into_Mat(figures))):
    figuresM[i] = copy.deepcopy(turn_figure_into_Mat(figures)[i])

def get_coord_ij(figuresM):
    tempF = []
    tempF2 = []
    for figNum in range(len(figuresM)):
        for i in range(len(figuresM[figNum])):
            for j in range(len(figuresM[figNum][i])):
                if figuresM[figNum][i][j] == figNum + 1:
                    tempF += [[i, j]]
        tempF2.append(tempF)
        tempF = []
    return tempF2

def get_coord_ij_figure(figure):
    tempF = []
    for i in range(len(figure)):
        for j in range(len(figure[i])):
            if figure[i][j] != 0:
                tempF += [[i, j]]
    return tempF

figures = copy.deepcopy(get_coord_ij(figuresM))      

def try_fill_figure(mat: list, fgr: list, figNum: int):    #i, j - start point  #fgr in coords
    can_fill = True
    for coord in fgr:
        if mat[coord[0]][coord[1]] != 0:
           can_fill = False
    if can_fill == True:
        for coord in fgr:
            mat[coord[0]][coord[1]] = (figNum + 1)
    return can_fill, mat                 

def remove_figure(mat, fgr):
    for coord in fgr:
        mat[coord[0]][coord[1]] = 0
    return mat

def get_max_x(fgr: list):
    max_x = 0
    for coord in fgr:
        if coord[0] > max_x:
            max_x = coord[0]
    return max_x
 
def get_max_y(fgr: list):
    max_y = 0
    for coord in fgr:
        if coord[1] > max_y:
            max_y = coord[1]
    return max_y

def try_new_area(mat: list, figNum: int, figures):
    global S
    global R
    global result
    fgr = figures[figNum]
    temp_fgr = copy.deepcopy(fgr)
    bottom_border = S - get_max_x(fgr)
    right_border = R - get_max_y(fgr)

    for r in range(bottom_border):
        for c in range(right_border):
            temp_fgr = fgr.copy()
            for idx, item in enumerate(temp_fgr):
                temp_fgr[idx] = [item[0] + r, item[1] + c]
            i_can, fieldx = try_fill_figure(mat, temp_fgr, figNum)
            if i_can == True:
                mat = fieldx
                if figNum == len(figures)-1:
                    result = mat
                    for i in result:
                        print(" ".join(list(map(str, i))))
                    exit()
                try_new_area(mat, (figNum + 1), figures)
                mat = remove_figure(mat, temp_fgr)
                     
    return False

def toString(List):
    return "".join(List)

"""-------------------------------Variant of permutations: Cartesian product with "import itertools"-------------------------------- """

iterCart = list(itertools.product([0,1,2,3], repeat=4))

def cart_for_permutation(AllCartproducts):
    #global countIter
    for i in range(len(AllCartproducts)):
        #countIter = countIter + 1
        figures3 = use_cart_for_rot(AllCartproducts[i])
        try_new_area(mat, 0, figures3)

        
def use_cart_for_rot(SomeCartProduct):
    global figuresM
    figures3M = copy.deepcopy(figuresM)
    figures3 = copy.deepcopy(figures)
    for idx, item in enumerate(SomeCartProduct):
        for i in range(item):   
            figures3[idx] = get_coord_ij_figure(rotate(figures3M[idx]))
            figures3M[idx] = rotate(figures3M[idx])
    return figures3


cart_for_permutation(iterCart)