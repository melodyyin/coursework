# GMMCLASSIFY
# uses the parameters derived from gmmest to classify a new testing set
# compares the log likelihoods from the two GMMs to find the GMM that each datapoint more likely belongs to
# FYI: hardcoded at k=2 because problem states that two GMMs exist
# outputs the accuracy of the classifier
# Author: Melody Yin
# Date: November 24th, 2014

import os
import sys
import numpy as np
import matplotlib.pyplot as plt

# replicating R dnorm function
# x = a value; m = mean; var = variance
def dnorm(x, m, var):
    return np.exp(-((x-m) ** 2) / (2 * var)) / np.sqrt(2 * np.pi * var)
    
def gmmclassify(x, mu1, sigmasq1, wt1, mu2, sigmasq2, wt2, p1):
    k = 2       #there are two GMMs
    N = len(x)
    
    # renaming..
    m1 = np.copy(mu1)
    var1 = np.copy(sigmasq1)
    w1 = np.copy(wt1)
    m2 = np.copy(mu2)
    var2 = np.copy(sigmasq2)
    w2 = np.copy(wt2)

    p2 = 1-p1
    
    ll1 = np.zeros(k)
    ll2 = np.zeros(k)
    
    classes = np.zeros(N)
    
    for n in range(N):
        # loglikelihood for GMM 1
        ll1_incr = 0
        ll2_incr = 0
        for j in range(k):
            ll1_incr = ll1_incr + p1 * w1[j] * dnorm(x[n], m1[j], var1[j])
        ll1 = np.sum(ll1_incr)
        # loglikelihood for GMM 2
        for j in range(k):
            ll2_incr = ll2_incr + p2 * w2[j] * dnorm(x[n], m2[j], var2[j])
        ll2 = np.sum(ll2_incr)
        
        if(ll1 > ll2):
            c = 1
        else:
            c = 2
            
        classes[n] = c
        
    return classes
    
def main():
    x = np.loadtxt(sys.argv[1], skiprows=1, delimiter=",")
    x = np.array(x)
    indic = np.where(x[:,1] == 1)

    m1 = np.loadtxt(sys.argv[2])
    m1 = np.array(m1)
    var1 = np.loadtxt(sys.argv[3])
    var1 = np.array(var1)
    w1 = np.loadtxt(sys.argv[4])
    w1 = np.array(w1)
    
    m2 = np.loadtxt(sys.argv[5])
    m2 = np.array(m2)
    var2 = np.loadtxt(sys.argv[6])
    var2 = np.array(var2)
    w2 = np.loadtxt(sys.argv[7])
    w2 = np.array(w2)
    p1 = sys.argv[8]
    p1 = np.float64(p1)

    res = gmmclassify(x, m1, var1, w1, m2, var2, w2, p1)
    
    y = np.array(x[:,1])
    len_y = len(y)
    
    # compare y and res 
    count = 0
    for i in range(len_y): 
        if(res[i] != y[i]):
            count = count + 1
    
    num = float(len_y - count)
    denom = float(len_y)
    accuracy = num/denom
    print accuracy
    
if __name__ == '__main__':
    main()