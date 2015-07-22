# GMMEST
# reads in a comma delimited file with two columns: x and y, where y is the binary class to which x belongs
# runs the EM algorithm using initial inputs for mean, variance and weight, as well as a set iteration
# outputs the new parameters after the user input number of iterations
# also prints a plot showing the increasing log likelihood as the algorithm iterates
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

def gmmest(x, mu_init, sigmasq_init, wt_init, its):
    k = len(mu_init)        # k is the number of gaussians 
    N = len(x)                  # N is the number of training data points
    
    # one for each k
    m = np.copy(mu_init)
    var = np.copy(sigmasq_init)
    w = np.copy(wt_init)
    
    count = 0
    responsibility = np.zeros(k*N).reshape(k, N)       # initialize the responsibility matrix of k rows and N columns
    gamma = np.zeros(k)         # initialize gamma as a vector of length k
    ll = np.zeros(its)              # initalize log likelihood as a vector of length its
    
    # repeat algorithm for input number of iterations
    while (count < its):
        # E STEP
        for n in range(N):
            denom = 0
            
            for j in range(k):
                denom = denom + (w[j] * dnorm(x[n], m[j], var[j]))      # gets the denom of responsibility per n 
            for j in range(k):
                responsibility[j, n] = w[j] * dnorm(x[n], m[j], var[j]) / denom
            for j in range(k):
                gamma[j] = np.sum(responsibility[j,:])
        # M STEP
        for j in range(k):
            w[j] = gamma[j] / N
            mu_incr = 0
            var_incr = 0
            for n in range(N):
                mu_incr = mu_incr + responsibility[j, n] * x[n]
                var_incr = var_incr + responsibility[j, n] * ((x[n] - m[j])**2)
            m[j] = mu_incr / gamma[j]
            var[j] = var_incr / gamma[j]
        
        # log likelihood
        loglike = np.zeros(N)       # log likelihood is the sum of all the likelihoods over all of the xs 

        for n in range(N):
            temp = 0
            for j in range(k):
                temp = temp + w[j] * dnorm(x[n], m[j], var[j])         # this is the likelihood under j-th model
            loglike[n] = np.log(temp)
                
        ll[count] = np.sum(loglike)
        
        count = count + 1
       
    return m, var, w, ll
   
def main():
    x = np.loadtxt(sys.argv[1], skiprows=1, delimiter=",")
    x = np.array(x)
    # separating the class 1 rows from class 2 rows
    indic = np.where(x[:,1] == 1)
    x_one = np.squeeze(x[indic,:])
    indic = np.where(x[:,1] == 2)
    x_two = np.squeeze(x[indic,:])
    
    m = np.loadtxt(sys.argv[2])
    m = np.array(m)
    var = np.loadtxt(sys.argv[3])
    var = np.array(var)
    w = np.loadtxt(sys.argv[4])
    w = np.array(w)
    its = sys.argv[5]
    its = np.int32(its)
    
    ll = gmmest(x_two[:,0], m, var, w, its)
    
    plt.plot(ll[3])
    plt.ylabel('log likelihood')
    plt.xlabel('iterations')
    plt.show()
    print "mu: ", ll[0], " sigmasq: ", ll[1], " wt: ", ll[2], " ll: ", ll[3]
    
if __name__ == '__main__':
    main()