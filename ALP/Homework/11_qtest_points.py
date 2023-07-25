import math
inp = input()

# To test:
# inp = " 0.0 1.0 2.0 3.0"
# inp = "0.5 1.0 0.5 4.0 1.0 3.0 1.0 1.0"
# inp = "-1.5 2 0 2 1 2 2 2 3 2 4 2 -1.5 3 0 3 1 3 2 3"

points = [float(i) for i in inp.split()]
tempList = []
newPoints = []
x_points = []
y_points = []
for i in range(0, len(points), 2):
    x_points.append(points[i])
    y_points.append(points[i+1])
    for k in range(2):
        tempList.append(points[i+k])
    newPoints.append(tempList)
    tempList = []
points[:] = newPoints

x_center = sum(x_points)/len(points)
y_center = sum(y_points)/len(points)

gravity = [x_center, y_center]
my_point = [points[0][0], points[0][1]]
counter = 0
radius = 0
circlePoint = []
min_length = math.sqrt((gravity[0]-points[0][0])**2 + (gravity[1]-points[0][1])**2)
for point in points:
    if min_length > math.sqrt((gravity[0]-point[0])**2 + (gravity[1]-point[1])**2):
        min_length = math.sqrt((gravity[0]-point[0])**2 + (gravity[1]-point[1])**2)
        my_point = [point[0], point[1]]
    radius = math.sqrt(point[0]**2 + point[1]**2)
    for i in range(len(points)):
        tempRadius = math.sqrt(points[i][0]**2 + points[i][1]**2)
        if tempRadius <= radius:
            counter+=1
    if counter == len(points)/2:
        circlePoint = [point[0], point[1]]
    counter = 0

print(points.index(my_point), points.index(circlePoint))



        
        
    




