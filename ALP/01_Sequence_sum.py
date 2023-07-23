
nums = list(map(int, input("Enter an order: ").split()))

from queue import Empty

#nums to test program
#nums = [0, -9, 3, 56, 7, 9, 6, 65, 4, 2, 1, -43, -105]
#nums = [4, 7, 8, 21, 45, 33, 22, 21, -100, 6, -45, -32, -21, 0, 4, 3]
# nums = [4, 7, 11, 23, 43, 33, 23, 19, -89, -97, -100, -97, -45, -32,
#         -21, 0, 1, 5, 3, 0, 4, 3, 17, 16, 15, 15, 13, 11, 7, 43, -13]
#nums = [-21, 0, 1, 5, 3, 0, 4, 3, 17, 16, 15, 15, 13, 11, 7, 43, -13]
#nums = [0, 1, 3, 1, 13, 11, 5, 64]
#nums = [6, 2]


def isPrime(n):
    p = 2
    if (abs(n) >= 2):
        while p < abs(n): 
            if (abs(n)%p) == 0:
                break
            p+=1
        if p < abs(n):
            return False
        else:
            return True
    else:
        return False



def repetitveList(nums):
    order = []
    result = []
    i = 1
    while i < len(nums):
        if (isPrime(nums[i-1])):
            #if (len(order) == 0) or (order[len(order)-1] != nums[i-1]):
            order.append(nums[i-1])
            #print("A:", result, i)
            if (nums[i-1] > nums[i]):
                if (isPrime(nums[i])):
                    order.append(nums[i])
                    #print("B:", result, i)
                else:
                    result += [order]
                    order = []
                    #print("C:", result, i)
            elif (nums[i-1] <= nums[i]):
                result += [order]
                order = []
                #print("D:", result, i)
            
                    
        i += 1
    if (len(order) != 0):
        result += [order]
        order = []
        
    if isPrime(nums[len(nums)-1]):
        order = []
        order.append(nums[len(nums)-1])
        result += [order]
        order = []
        
    return result
    
       
print(nums)
print("-----------------")
print(repetitveList(nums))

def removeDublicates(nums):
    res = []
    #nums = list(dict.fromkeys(nums))
    for i in range(len(nums)):
        res.append([])
        for j in range(len(nums[i])):
            if nums[i][j] not in res[i]:
                res[i].append(nums[i][j])
    return res


def findTheRightList(list):
    list_len = []
    list_sum = []
    my_len = 0
    my_sum = 0
    for i in range(len(list)):
        list_len.append(len(list[i]))
        try:
            if list_len[i]>=len(list[i+1]):
                list_sum.append(sum(list[i]))
            else:
                list_sum.append(sum(list[i+1]))
            if list_len[i] == max(list_len):
                #print(i, list_len[i], list_sum[i])
                #if list_sum[i] == max(list_sum):
                    my_len = list_len[i]
                    my_sum = list_sum[i]
                    #print(list_sum[i])    
                   
            elif len(list_len) == 0:
                return 0
        except: pass
        
        
    return my_len, my_sum

    
print(removeDublicates(repetitveList(nums)))
print(findTheRightList(removeDublicates(repetitveList(nums))))
#print(removeDublicates(nums))
# print(isPrime(int(input("Enter: "))))




