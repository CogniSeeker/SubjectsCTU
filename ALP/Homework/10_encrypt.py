from sys import argv

# Comment it to test program
n = int(argv[1])
e = int(argv[2])
text = str(input())

# To test program:

# 1st ex:
# n = 1015282856477 
# e = 914394312011
# text = "ahoj, jak se mate?"

# 2nd ex:
# n = 854757130933 
# e = 339289
# text = "Slava! Mate to hotove."

def DivideTextOnBlocks(text):
    textTemp = []
    tempList = []
    for i in range(len(text)):
        if i%4 == 0:
            tempList.append(text[i])
            if i+1 < len(text):
                tempList.append(text[i+1])
            if i+2 < len(text):
                tempList.append(text[i+2])
            if i+3 < len(text):
                tempList.append(text[i+3])
        if tempList != []:
            textTemp.append(tempList)
        tempList = []
    text = textTemp
    return text

#find GCD (greatest common divisor)
def ExtEuclid(a, b):
    Aa, Ba = 1, 0  # a = 1 * a + 0 * b
    Ab, Bb = 0, 1  # b = 0 * a + 1 * b
    if b > a:
        a, b = b, a
        Aa, Ab = Ab, Aa
        Ba, Bb = Bb, Ba
    # Here, a is always greater than or equal to b
    while b > 0:
        # Subtract b from a as many times as it fits
        Aa = Aa - (a // b) * Ab
        Ba = Ba - (a // b) * Bb
        # GCD(a % b, b) = GCD(a, b)
        a = a % b
        a, b = b, a
        Aa, Ab = Ab, Aa
        Ba, Bb = Bb, Ba
    # GCD(0, a) = a.
    # Also return Bézout's coefficients.
    return (a, Aa, Ba)

#raise A to power K quickly
def FastExpMod(a, k, n): 
    if k == 0: return 1
    if k == 1: return a

    # If 'k' is even, return (a^(k/2))^2.
    # If 'k' is odd, return a * a^(k - 1).

    if k % 2 == 0:
        i = FastExpMod(a, k / 2, n)
        return (i * i)%n    #(x^e)%n
    else:
        return (a * FastExpMod(a, k - 1, n))%n
"""---------------------------------------"""
#other method of raising to power uses it
def multiply(x, res, res_size):
    carry = 0
    for i in range(res_size):
        prod = res[i] * x + carry
        # Store last digit of
        # 'prod' in res[]
        res[i] = prod % 10
 
        # Put rest in carry
        carry = prod // 10
 
    while (carry):
        res[res_size] = carry % 10
        carry = carry // 10
        res_size+=1
 
    return res_size

def Encrypt(n, e, text):
    encryption = [] #encryption by unicode and formula X
    cipher = [] #final cipher
    text = DivideTextOnBlocks(text)
    """change []" to [' ']"""
    for i in range(len(text)):  
        for j in range(len(text[i])):
            if text[i][j] == []:
                text[i][j] = [' ']
    print("CHR: ", chr(0))
    """main code"""
    for element in text:
        if element != text[-1]: 
            a = element[0][0]
            b = element[1][0]
            c = element[2][0]
            d = element[3][0]
        else:    #if it is last element
            a = element[0][0]
            if len(element) == 4:
                b = element[1][0]
                c = element[2][0]
                d = element[3][0]
            elif len(element) == 3:
                b = element[1][0]
                c = element[2][0]
                d = chr(0)  # number, for which order(number) = 0
            elif len(element) == 2:
                b = element[1][0]
                c = chr(0)
                d = chr(0)
            elif len(element) == 1:
                b = chr(0)
                c = chr(0)
                d = chr(0)
        x = ( (ord(a)*256 + ord(b))*256 + ord( c ) )*256 + ord(d)   #ord(chr(0)) = 0
        encryption.append(x) # we have message encrypted in unicode with formula X
    for element in encryption:
        cipher.append(FastExpMod(element, e, n))    # (x^e)%n
    return cipher

print(' '.join(str(x) for x in Encrypt(n, e, text)))