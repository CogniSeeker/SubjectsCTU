import sys
import time
import os

start = time.time()
a = []

# To test:
# take 05_diag.txt from test_data_input folder

f = open(sys.argv[1], 'r')
for line in f:
    a.append(list(map(int, line.split())))
        
for row in a:
    print(row)

def is_prime(number):
    if number % 2 == 0:
        return True
    else:
        return False
    
def find__sequence(lst):
    M, N = len(lst), len(lst[0])
    count = 0   # count len
    maxcountR = 0
    maxcountL = 0
    idxMR = 0       #final 1st index of row for right-diagonal direction
    idxNR = 0       #final 1st index of row for right-diagonal direction
    idxML = 0       #final 1st index of row for left-diagonal direction
    idxNL = 0       #final 1st index of row for left-diagonal direction
    k = 0           #iteration of diagonal 
    i = 0
    j = 0
    while i < M:
        while j < N:
            if is_prime(a[i][j]):
                if (i+1) < M and (j+1) < N and is_prime(a[i+k+1][j+k+1]):
                    count = 1
                    while  (i+k+1) < M and (j+k+1) < N and is_prime(a[i+k+1][j+k+1]):
                        count += 1
                        k += 1   
                    k = 0
                    if count > maxcountR:
                        maxcountR = count
                        idxMR = i
                        idxNR = j
                    count = 0 
                if (i+1) < M and (j-1) >= 0 and is_prime(a[i+k+1][j-k-1]):      #check for first iterstion
                    count = 1
                    while  (i+k+1) < M and (j-k-1) >= 0 and is_prime(a[i+k+1][j-k-1]):
                        count += 1
                        k += 1
                    k = 0
                    if count > maxcountL:
                        maxcountL = count
                        idxML = i
                        idxNL = j
                    count = 0 
            j += 1
        j = 0
        i += 1
    if maxcountR >= maxcountL:
        maxcount = maxcountR
        idxM = idxMR
        idxN = idxNR
    else:
        maxcount = maxcountL
        idxM = idxML
        idxN = idxNL           
    print(idxM, idxN, maxcount)
 
           
find__sequence(a)
    
end = time.time()
print("The time of execution of above program is :",
      (end-start)  * 10**3, "ms")