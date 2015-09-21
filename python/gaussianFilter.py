#
# Copyright (C) 2015 Project
# based on code by Edward Lin
# License: http://www.gnu.org/licenses/gpl.html GPL version 2 or higher
#
# Software implementation of 2D filter seperable kernel
# Created 7/27/15
# By Edward Lin
# Utilizes Python Imaging Library (PIL).  By default in Python2.7 in Ubuntu.  
# Otherwise need to download at pythonware.com/products/pil/

import os, sys
from PIL import Image
from fractions import Fraction

#gaussian elimination to verify matrix is separable 
def gaussianElimSep(origMatrix):
    #copy original matrix to temp matrix so don't overwrite original
    curMatrix = []
    for x in range(len(origMatrix)):
        curMatrix.append(list(origMatrix[x]))

    #curMatrix should be a square matrix
    matrixMaxRow = len(curMatrix)
    if len(curMatrix) < matrixMaxRow:
        sys.exit('Kernel matrix is not separable')  

    for c in range(0, matrixMaxRow):
        maxValue = abs(curMatrix[c][c])
        maxRow = c
        # Find maximum in column
        for r in range(c + 1, matrixMaxRow):
            if abs(curMatrix[r][c]) > maxValue:
                maxValue = abs(curMatrix[r][c])
                maxRow = r

        # Move maxRow to curRow
        for curCol in range(c, matrixMaxRow):
            curValue = curMatrix[maxRow][curCol]
            curMatrix[maxRow][curCol] = curMatrix[c][curCol]
            curMatrix[c][curCol] = curValue
 
        # zero out rows in column
        for curRow in range(c+1, matrixMaxRow):
            if curMatrix[c][c] != 0.0:
                constVal = -curMatrix[curRow][c]/curMatrix[c][c]
                for curCol in range(c, matrixMaxRow):
                    if c == curCol:
                        curMatrix[curRow][curCol] = 0
                    else:
                        curMatrix[curRow][curCol] += constVal * curMatrix[c][curCol]
    #matrix is separable if rank = 1.  Only first row should have values
    for r in range(1, matrixMaxRow):
        for c in range(0, matrixMaxRow):
            if curMatrix[r][c] != 0.0:
                return ()
    for c in range(0, matrixMaxRow):
        if curMatrix[0][c] != 0.0:
            return (curMatrix[0])
    return ()

def conv2Dsep(imageMatrix, filterRow, filterCol):
    #tuple of dimensions
    imageDim = (len(imageMatrix), len(imageMatrix[0]))
    filterRowLen = len(filterRow)
    filterColLen = len(filterCol)
    newImage = []

    totalMults = 0
    #for every row
    for i in range(imageDim[0]):
        #for every col
        newImageCol = []
        for j in range(imageDim[1]):
            sum = 0.0
            #row filter
            for k in range(filterRowLen):
                n = j + k - filterRowLen/2
                if n >= 0 and n < imageDim[1]:
                    sum += imageMatrix[i][n]*filterRow[k]
                    totalMults += 1
            newImageCol.append(sum)
        newImage.append(newImageCol)
    newImage2 = []
    #for every row
    for i in range(imageDim[0]):
        #for every col
        newImageCol = []
        for j in range(imageDim[1]):
            sum = 0.0
            #col filter
            for k in range(filterColLen):
                m = i + k - filterColLen/2
                if m >=0 and m < imageDim[0]:
                    sum += newImage[m][j]*filterCol[k]
                    totalMults +=1
            if sum < 0.0:
                sum == 0.0
            elif sum > 255.0:
                sum = 255.0

            newImageCol.append(sum)
        newImage2.append(newImageCol)
    print "***********************"
    print "Optimized separable convolution 2D"
    print "Image Dimensions: Row=" + str(imageDim[0]) + " Col=" + str(imageDim[1])
    print "Total Pixels: " + str(imageDim[0] * imageDim[1])
    print "Total Multipliers:" + str(totalMults)
    print "***********************"

    return newImage2

def conv2D(imageMatrix, filterMatrix):
    #tuple of dimensions
    imageDim = (len(imageMatrix), len(imageMatrix[0]))# num of row then num of col
    filterDim = (len(filterMatrix), len(filterMatrix[0])) # num of row then num of col
    newImage = []
    
    totalMults = 0
    #for every row
    for i in range(imageDim[0]):
        #for every col
        newImageCol = []
        for j in range(imageDim[1]):
            sum = 0.0
            #row filter
            for k in range(filterDim[0]):
                #col filter
                for l in range(filterDim[1]): 
                    m = i + k - filterDim[0]/2
                    n = j + l - filterDim[1]/2
                    if m >= 0 and m < imageDim[0] and n >= 0 and n < imageDim[1]:
                        sum += imageMatrix[m][n]*filterMatrix[k][l]
                        totalMults += 1
            if sum < 0.0:
                sum == 0.0
            elif sum > 255.0:
                sum = 255.0

            newImageCol.append(sum)
        newImage.append(newImageCol)
    print "***********************"
    print "Basic convolution 2D without optimization"
    print "Image Dimensions: Row=" + str(imageDim[0]) + " Col=" + str(imageDim[1])
    print "Total Pixels: " + str(imageDim[0] * imageDim[1])
    print "Total Multipliers:" + str(totalMults)
    print "***********************"

    return newImage    

if len(sys.argv) != 4 and len(sys.argv) != 5:
    sys.exit('Usage: %s <inputImageFile> <inputFilterFile> <outputImageFile> <optional:outputAsciiPixelFile>' % sys.argv[0])
    
inputImageFile = sys.argv[1]
inputFilterFile = sys.argv[2]
outputImageFile = sys.argv[3]

if len(sys.argv) == 5:
    debugImageFile = sys.argv[4]
else:
    debugImageFile = ""

#check if filter is separable. Rank of 1
try:
    inputFilterPtr = open(inputFilterFile, 'r')
except:
    sys.exit('Unexpected error opening: %s' % inputFilterFile)

#initialize filter
filterKernel = []
filterConst = 1.0
filterConstSet = False
for i in inputFilterPtr:
    if filterConstSet == False:
        filterConst = float(Fraction(i.strip()))
        filterConstSet = True
    else:
        rowList = [float(x) for x in i.strip().split()]
        filterKernel.append(rowList)

inputFilterPtr.close()
if len(filterKernel) == 0:
    sys.exit('Not enough data found in %s' % inputFilterFile)
elif len(filterKernel) < len(filterKernel[0]):
    sys.exit('Columns greater than the number of Rows in %s. Filter not separable' % inputFilterFile)

#check if it's separable
H1 = gaussianElimSep(filterKernel)
if H1 == ():
    sys.exit('Kernel filter is not separable')
else:
    #create the other separable filter
    H2 = []
    for f in filterKernel[0]:
        H2.append(float(f)*filterConst/float(H1[0]))    

#add constant
for x in range(len(filterKernel)):
    for y in range(len(filterKernel[0])):
        filterKernel[x][y] = filterKernel[x][y] * filterConst

#open image
try:
    inputImagePtr = Image.open(inputImageFile, 'r')
except:
    sys.exit('Unexpected error opening: %s' % inputImageFile)

imageWidth, imageHeight = inputImagePtr.size
dataPix = list(inputImagePtr.getdata())

dataPix2D = []
curPixelIndex = 0
for iH in range(imageHeight):
    dataPix2D.append(dataPix[curPixelIndex:curPixelIndex + imageWidth])
    curPixelIndex += imageWidth

newImage2D = conv2D(dataPix2D, filterKernel)
newImage2Dsep = conv2Dsep(dataPix2D, H1, H2)

if newImage2D != newImage2Dsep:
    print "Separable convolution not equal to original convolution"
    for i in range(len(newImage2D)):
        for j in range(len(newImage2D[0])):
            if (newImage2D[i][j] != newImage2Dsep[i][j]):
                print "[" + str(i) + "][" + str(j) + "]="+str(newImage2D[i][j])
                print str(newImage2Dsep[i][j])
                print "---"
else:
    print "Separable convolution matches original convolution"

#write new Image back out
newImage = sum(newImage2D, [])
newImagePtr = Image.new(inputImagePtr.mode, (imageWidth, imageHeight))
newImagePtr.putdata(newImage)
newImagePtr.save(outputImageFile, inputImagePtr.format)
