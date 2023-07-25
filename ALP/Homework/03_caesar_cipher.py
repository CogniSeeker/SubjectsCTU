# Enter the number of characters
n = int(input())
b = []
a = []

# To test program
# b = [[4484386, 5430482], [997155, 6818895], [2444051, 6275419]]
# n = 3

if n == 0:
    print("ERROR")
    exit()

while n > 0: 
    a = list(map(int,input().strip().split())) # Enter the number
    b.append(a)
    for i in range(len(b)):
        if len(b[i]) != 2 or ((type(b[i][0]) or type(b[i][1])) is not int): 
            print("ERROR")
            exit()
    n -= 1    

result = []

a = []
t = 0 # variable to make an exchange
y = 0 # final variable-result
def count_caesar(b):
    for i in range(len(b)):
        while (b[i][0] and b[i][1] != 0):
            if (b[i][0] > b[i][1]):
                t = b[i][1]
                y = b[i][1]
                b[i][1] = b[i][0]%b[i][1]
                b[i][0] = t
                #print ("y", y) # control the output
            elif (b[i][0] < b[i][1]):
                t = b[i][0]
                y = b[i][0]
                b[i][0] = b[i][1]%b[i][0]
                b[i][1] = t

                #print("y:", y) # control the output
        result.append(chr(y))
        #print("result: ", result) #control the output
    p = ''
    p = p.join(result)
    return p
        
print(count_caesar(b))
