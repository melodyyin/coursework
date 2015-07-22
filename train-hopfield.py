# TRAIN_HOPFIELD
# reads in binary training data from image processing 
# utilizes hopfield networks 
# to output weight vector with the input pattern embedded within it
# Author: Melody Yin
# Date: November 24th, 2014

import sys
import os
import numpy as np

def train_hopfield(x):
    dim = x.shape
    nrow = int(dim[0])          #nrow is the number of training examples
    ncol = int(dim[1])          #ncol x ncol is the dim of the weight vector
    
    w = np.zeros((ncol, ncol), dtype=np.int)            # initialize weight vector
    
    # fill in the weight vector
    # 1) fill in every value from i, j=i+1 (i.e, row1 would have w1,2 thru w1,ncol filled ; row1593 would have none filled b/c w1593, 1594 is out of range
    # 2) reflect the matrix since weight matrix is symmetric
    for i in range(ncol):
        for j in range(i+1, ncol):                                                      #for consistency with the slides 
            for c in range(nrow):
                w[i, j] = w[i, j] + x[c, i] * x[c, j]         #wij is the weight of the i-th training example 
    
    return w + w.T
    
def main():
    # training data should be binary (-1, 1) 
    x = np.loadtxt(sys.argv[1])
    x = np.array(x, np.int32)       # convert from float 
    
    dim = x.shape
    nrow = int(dim[0])      #nrow is the number of training examples
    ncol = int(dim[1])      #ncol x ncol is the dim of the weight vector
    
    # training data should be binary (-1, 1) 
    for r in range(nrow):
        for c in range(ncol):
            if(x[r,c] == 0):
                x[r,c] = -1
    
    w = train_hopfield(x)
    print w

if __name__ == '__main__':
    main()