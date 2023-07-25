from sys import argv

# To test:
# take .txt file from test_data_input/08_test_data folder

with open(argv[1], 'r') as f:
    field = [list(map(str, line.split())) for line in f]
    
def printMat(mat):
    for row in mat:
        print(row)
        
global R
global C

R = len(field)
C = len(field[0])

def inside(mat, i, j):
    R = len(mat)
    C = len(mat[0])
    if i <= -1 or i >= R:
        return False
    if j <= -1 or j >= C:
        return False
    return True

def iterate(field):
    global R
    global C
    tempWay =[]
    numDartCycle = 0 #number of dark cycles
    numLightCycle = 0
    maxLengthD = 0
    maxLengthL = 0
    lengthD = 0
    lengthL = 0
    wayD = []
    wayL = []
    for si in range(R):     #si - start point i
        for sj in range(C): #sj - start point j
            """--- find dark cycle ---"""
            #None-condition is VERY IMPORTANT
            if wayD.count([si, sj]) == 0 and find_cyclus(field, si, sj, 'd') != None:
                cycle = find_cyclus(field, si, sj, 'd')[0]
                if cycle == True:
                    lengthD = find_cyclus(field, si, sj, 'd')[1]
                    tempWay = find_cyclus(field, si, sj, 'd')[2]
                    for element in tempWay:
                        wayD.append(element)
                    numDartCycle += 1
                    tempWay = []
                    cycle = False
                    if lengthD > maxLengthD:
                        maxLengthD = lengthD
            """--- find light cycle ---"""
            #None-condition is VERY IMPORTANT
            if wayL.count([si, sj]) == 0 and find_cyclus(field, si, sj, 'l') != None:
                cycle = find_cyclus(field, si, sj, 'l')[0]
                if cycle == True:
                    lengthL = find_cyclus(field, si, sj, 'l')[1]
                    tempWay = find_cyclus(field, si, sj, 'l')[2]
                    for element in tempWay:
                        wayL.append(element)
                    numLightCycle += 1
                    tempWay = []
                    cycle = False
                    if lengthL > maxLengthL:
                        maxLengthL = lengthL
    return numLightCycle, numDartCycle, maxLengthL, maxLengthD
                
        
def find_cyclus(field, si, sj, color): 
    startI = si
    startJ = sj  
    lengthCycle = 0
    side2neightboors = [2, 3, 0, 1]
    way = [[si, sj]]
    i = 0
    while i < 4:
        if field[si][sj][i] == color:
            if i == 0:
                if inside(field, si, sj-1) and field[si][sj-1][side2neightboors[0]] == color:
                    if si == startI and sj-1 == startJ and lengthCycle != 2:
                        cycle = True
                        return [cycle, lengthCycle, way]
                    if way.count([si, sj-1]) != 0:
                        i+=1
                        continue
                    way += [[si, sj-1]]
                    sj = sj-1
                    lengthCycle = len(way)
                    i = 0
                    continue                  
            if i == 1:
                if inside(field, si-1, sj) and field[si-1][sj][side2neightboors[1]] == color:
                    if si-1 == startI and sj == startJ and lengthCycle != 2:
                        cycle = True
                        return [cycle, lengthCycle, way]
                    if way.count([si-1, sj]) != 0:
                        i+=1
                        continue
                    way += [[si-1, sj]]
                    si = si-1
                    lengthCycle = len(way)
                    i = 0
                    continue                   
            if i == 2:
                if inside(field, si, sj+1) and field[si][sj+1][side2neightboors[2]] == color:
                    if si == startI and sj+1 == startJ and lengthCycle != 2:
                        cycle = True
                        return [cycle, lengthCycle, way]
                    if way.count([si, sj+1]) != 0:
                        i+=1
                        continue
                    way += [[si, sj+1]]
                    sj = sj+1
                    lengthCycle = len(way)
                    i = 0
                    continue                   
            if i == 3:
                if inside(field, si+1, sj) and field[si+1][sj][side2neightboors[3]] == color:
                    if si+1 == startI and sj == startJ and lengthCycle != 2:
                        cycle = True
                        return [cycle, lengthCycle, way]
                    if way.count([si+1, sj]) != 0:
                        i+=1
                        continue
                    way += [[si+1, sj]]
                    si = si+1 
                    lengthCycle = len(way)                        
                    i = 0
                    continue
        i+=1
                     
print(" ".join(list(map(str, iterate(field)))))             
                
        

