#Coursework Code Samples
I have uploaded a few things I have worked on this past year. Hopefully, they can serve as reference for other students. Suggestions for improvements are very welcome.

- **relationship-model.nlogo**, **relationship-model-hubnet.nlogo**: A [NetLogo](https://ccl.northwestern.edu/netlogo/) model that explores how relationships form. The user can adjust macro-level variables and observe how successful relationships, unhappy relationships and single individuals form. For more information, open the model in NetLogo and click on the Info tab.
- **one-direction-game.pl**: A simple game written in [Prolog](http://www.swi-prolog.org/) where the player's goal is to date a member of One Direction. The player visits various locations to find members and to better his/her chances at getting 1/5 to agree to a date. However, the player has only a limited amount of resources and must reach the goal before time or money runs out! 
- **viterbi.py**: An implementation of the Viterbi algorithm in [Python](https://www.python.org/).
- **sudoku.py**: Methods for a Sudoku solver, written in Python.
- **naive-bayes.py**: Uses the Naive Bayes algorithm and the Chi-Squared test to perform sentiment analysis on various movie reviews, written in Python.
- **nfoldpolyfit.py**: plots MSE vs. kth polynomial regressions (for k from 0 to 9) using n-fold cross-validation given X and Y values in a csv file and fits the best choice k on data, written in Python and can be run with 
```python
python nfoldpolyfit.py csvfile maxk nfolds verbose
```
- **train_hopfield.py**: trains hopfield network on binary image data from the [Semeion handwriting digit data set](https://archive.ics.uci.edu/ml/datasets/Semeion+Handwritten+Digit) and outputs weight vector
```python
python train_hopfield.py datafile
```
- **gmmest.py**, **gmmclassify.py** - uses the EM algorithm to estimate parameters of Gaussian Mixture Model and then classifies points according to learned GMM 
```python
python gmmest.py datafile mu_init var_init wt_init iterations
python gmmclassify.py datafile mu1 var1 wt1 mu1 var1 wt1 prior1
```
- **basics.rkt**: A few basic functions in [Scheme/Racket](http://racket-lang.org/). 
- **garbage-collector.rkt**: An implementation of a two space copying collector in Scheme/Racket.