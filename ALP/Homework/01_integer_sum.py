
# calculates the sum of powered numbers to 3

# Example:
# In:
# 2
# 5
# Out:
# 224

a = int(input())
b = int(input())
sum = 0

if a <= b:
    for i in range(a, b+1):
        sum += a**3
        a += 1
    print(sum)
else:
    for i in range(b, a+1):
        sum += b**3
        b += 1
    print(sum)