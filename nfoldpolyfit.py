# NFOLDPOLYFIT finds the line of best fit  given a n-fold value and a maxK polynomial value
# dataset is first divided into tn-fold training/test sets depending on user input
# then, using the method of minimizing mean squared error, the best fit on the training sets for each k is found
# of  these best fits, the bestEST fit is found by selecting the fit with the lowest mean squared error out of  this set
# then, the results are plotted depending on verbose value
# AUTHOR: Yi(Melody) Yin
# DATE: October 22nd, 2014

import sys 
import os
import pandas as pd
import numpy as np
import scipy.stats as ss
from sklearn import cross_validation
import matplotlib.pyplot as plt

def nfoldpolyfit(x, y, maxK, n, verbose): 
    kf = cross_validation.KFold(len(x), n_folds=n)
    fit_arr = []
    mse_arr = []
    mses = []
    
    for i in range(maxK+1):
        for train_i, test_i in kf:
            x_train, x_test = x[train_i], x[test_i]
            y_train, y_test = y[train_i], y[test_i]
            
            fit = np.polyfit(x_train, y_train, i)
            fit_arr.append(fit)
                
            sse = np.sum((np.polyval(fit, x_test) - y_test) **2)
            mse = sse/len(x)     # mse for THIS training set
            mse_arr.append(mse)
        
        count = mse_arr.index(min(mse_arr))  # count+1 reveals the number of iteration that the min was found
        mses.append(min(mse_arr))   # a list of the smallest mses from each fold
        mse_arr = []    # reset mse array after each k change
    
    indic = mses.index(min(mses)) # best k value
    best = n * indic + (count+1)    #index of best fit 
    
    # setting up plot
    z = fit_arr[best]
    p = np.poly1d(z)
    xp = np.linspace(-1, 1, 100)
    
    # show plot
    if verbose==1:
        horiz = range(maxK+1)
        plt.figure(1)
        plt.plot(horiz, mses)
        plt.figure(2)
        plt.plot(x, y, '.', xp, p(xp), '-')
        plt.show()

def main():
    fl = pd.read_csv(sys.argv[1])
    x = fl['X']
    y = fl['Y']
    
    nfoldpolyfit(x, y, int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]))

if __name__ == '__main__':
    main()