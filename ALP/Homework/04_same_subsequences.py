
numbers = list(map(int, input().split()))

# Uncomment it for test:

# in:
# numbers = [1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 5, 6]
# out:
# 4 2 6 

# in:
# numbers = [1, 2, 3, 4, 5, 6, 5, 7, 8, 9]
# out:
# 1 4 6

def find_two_sequences(lst):
    k = 0   # index from which we start in big list
    i = 0   # index of element in big list
    templst = []
    bigtemplst = []
    result = []
    while i < len(lst):   # all elements of big list
        if  templst == []:      # when i == 0 (first cycle)
            templst = [lst[0+k]]
        if i != 0 and len(lst[k:i+k]) != 0:
            templst = []
            templst = lst[k:i+k]    # [:i]
        bigtemplst = lst[:k] + lst[i+k:]    # [i+1:]
        if len(templst) <= len(bigtemplst):
            if list_match(templst, bigtemplst):       
                result.append([templst, [k], [list_idx2(templst, bigtemplst)+i]]) 
        else:
            templst = []
            bigtemplst = []
            k += 1
            i = 0
        i += 1                                           
    return result


def find_max_list(list):
    idx1 = list [1][1][0]
    idx2 = list[1][2][0]
    if len(list[1][0]) == 1:
        maxlen = len(list[1][0])
    else:
        maxlen = len(list[0][0])
        idx1 = list [1][1][0]
        idx2 = list[1][2][0]
    for i in range(len(list)):
        if (len(list[i][0]) > maxlen):
            maxlen = len(list[i][0])
            idx1 = list[i][1][0]
            idx2 = list[i][2][0]
    print(maxlen, idx1, idx2)

def list_match(a, b):
    for i in range(len(b)):
        if a[0] == b[i]:
            if len(b[i:]) >= len(a):
                c = 0
                for j in range(len(a)):
                    if a[j] == b[j+i]:
                        c += 1
                        if c == len(a):
                            return True
                        continue
                    else:
                        break
            else:
                return False
            
def list_idx2(a, b):
    for i in range(len(b)):
        if a[0] == b[i]:
            if len(b[i:]) >= len(a):
                c = 0
                for j in range(len(a)):
                    if a[j] == b[j+i]:
                        c += 1
                        if c == len(a):
                            return i
                        continue
                    else:
                        break
            else:
                return 0
            
find_max_list(find_two_sequences(numbers))
            
