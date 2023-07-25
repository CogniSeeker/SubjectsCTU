y = float(input())

def getInitialInterval(y):
    if y > 1:
        x1 = 0
        x2 = y
    elif (y < 1) and (y > 0):
        x1 = -1/y
        x2 = 0
    else:
        print("Error: incorrect number entered!")
    return x1, x2

def find_logarithm(y):
    x1, x2 = getInitialInterval(y)
    while (abs(x1 - x2) >= 0.000000001):
        x = (x1 + x2) / 2.0
        fx = 2**x - y
        if fx > 0:
            x2 = x
        elif fx == 0:
            break
        else:
            x1 = x
    return x

print(find_logarithm(y))