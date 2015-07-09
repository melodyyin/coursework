# Name: Yi (Melody) Yin
# Date: May 22nd, 2015
# Description: Assignment 4
#
#

import math, os, pickle, re
import scipy.stats as ss 
import random

class Bayes_Classifier:

   def __init__(self, cv=False, folds=10):
      """This method initializes and trains the Naive Bayes Sentiment Classifier.  If a 
      cache of a trained classifier has been stored, it loads this cache.  Otherwise, 
      the system will proceed through training.  After running this method, the classifier 
      is ready to classify input text."""
      self.negd = dict()
      self.posd = dict()
      self.posNew = dict()
      self.negNew = dict()

      if cv == False:
         try:
            self.negd = self.load("neg_dict.dat")
            self.posd = self.load("pos_dict.dat")
         except:
            self.train()
            self.train_new()  # make the new dictionary, then wait for user to call classify()
      else:
         self.cv(folds)    # make the new dictionary + do cross-validation 

   # FREQUENCY not presence 
   def train(self):   
      """Trains the Naive Bayes Sentiment Classifier."""
      fileList = []
      for f in os.walk("reviews/"):
         fileList = f[2] 
         break 

      # rating is at position 7 
      fileClass = []
      for f in fileList:
         if int(f[7]) == 1:
            fileClass.append("-")
         elif int(f[7]) == 5:
            fileClass.append("+")
         else:
            return "something weird happened"

      total = len(fileClass)

      for i in range(total):
         fileName = "reviews/" + fileList[i]
         review = self.loadFile(fileName)
         words = self.tokenize(review)
      
         if fileClass[i] == '-':
            for word in words:
               if word in self.negd:
                  self.negd[word] = self.negd[word] + 1
               else:
                  self.negd[word] = 1
         elif fileClass[i] == '+':
            for word in words:
               if word in self.posd:
                  self.posd[word] = self.posd[word] + 1
               else:
                  self.posd[word] = 1
         else:
            return "something weird happened 2"

      try:
         self.save(self.negd, "neg_dict.dat")
         self.save(self.posd, "pos_dict.dat")
      except:
         print "something weird happened 3"

   def train_new(self):
      """Trains a new dictionary that removes irrelevant words from the previous dictionary"""
      # resets, so that a new dictionary can be built in the next iteration
      self.posNew.clear()
      self.negNew.clear()

      posdLen = len(self.posd)
      negdLen = len(self.negd)
      # posSorted is a list of tuples in the form (word, count)
      posSorted = sorted(self.posd.items(), key=lambda x: x[1], reverse=True)
      firstCount = posSorted[0][1]  # the number of times the most popular word occurred 
      count = 0

      posExpected = []
      posObserved = []

      for pairs in posSorted:
         count = count + 1
         # leveraging Zipf's law: the expected count is inversely proportional to the rank
         posExpected.append(int(round(firstCount / float(count))))
         posObserved.append(pairs[1])

      # negSorted is a list of tuples in the form (word, count)
      negSorted = sorted(self.negd.items(), key=lambda x: x[1], reverse=True)
      firstCount = negSorted[0][1]
      count = 0

      negExpected = []
      negObserved = []

      for pairs in negSorted:
         count = count + 1
         negExpected.append(int(round(firstCount / float(count))))
         negObserved.append(pairs[1])

      # chisq test 
      # if p-value is < 0.005 (0.05/10 ; multiple testing correction applied to avoid false discoveries)
      # we can be less conservative (i.e., remove more words) by adjusting the p-value cutoff upwards 
      # shows that there is an effect -> keep words in dictionary
      # o.w. can remove words from dictionary
      # pos filtering 
      b = 0
      for tens in range(10, posdLen, 10):
         chisq = ss.chisquare(posObserved[b:tens], posExpected[b:tens], ddof=1)
         pval = chisq[1]

         if pval < 0.005:
            del posSorted[b:tens]

         b = tens 

      if b < (posdLen-1):
         chisq = ss.chisquare(posObserved[b:posdLen], posExpected[b:posdLen], ddof=1)
         pval = chisq[1]

         if pval < (0.05/(posdLen-b)):
            del posSorted[b:posdLen]

      # neg filtering 
      b = 0
      for tens in range(10, negdLen, 10):
         chisq = ss.chisquare(negObserved[b:tens], negExpected[b:tens], ddof=1)
         pval = chisq[1]

         if pval < 0.005:
            del negSorted[b:tens]

         b = tens

      if b < (negdLen-1):
         chisq = ss.chisquare(negObserved[b:negdLen], negExpected[b:negdLen], ddof=1)
         pval = chisq[1]

         if pval < (0.05/(negdLen-b)):
            del negSorted[b:negdLen]

      for pairs in posSorted:
         self.posNew[pairs[0]] = pairs[1]
      for pairs in negSorted:
         self.negNew[pairs[0]] = pairs[1]

      posNewLen = len(self.posNew)
      negNewLen = len(self.negNew)

   def classify(self, sText):
      """Given a target string sText, this function returns the most likely document
      class to which the target string belongs (i.e., positive, negative or neutral).
      """
      # posNew and negNew already exists here so don't have to load
      posNewLen = len(self.posNew)
      negNewLen = len(self.negNew)

      words = self.tokenize(sText)
      posPrior = float(posNewLen)/(posNewLen+negNewLen)
      negPrior = 1-posPrior
      # add one smoothing
      wordPosLikelihood = math.log(1.0/posNewLen)
      wordNegLikelihood = math.log(1.0/negNewLen)

      # pretty much copied from simple naive bayes
      for word in words:
         if word in self.posNew:
            wordPosLikelihood = wordPosLikelihood + math.log(float(self.posNew[word])/posNewLen)
         if word in self.negNew:
            wordNegLikelihood = wordNegLikelihood + math.log(float(self.negNew[word])/negNewLen)

      posPosterior = wordPosLikelihood + math.log(posPrior)
      negPosterior = wordNegLikelihood + math.log(negPrior)

      if posPosterior > negPosterior:
         return "positive"
      elif posPosterior < negPosterior:
         return "negative"
      else:
         rand = random.random()
         if rand < posPrior:
            return "positive/neutral"
         else:
            return "negative/neutral"

   # cross-validation 
   def cv(self, folds):
      # training
      fileList = []
      for f in os.walk("reviews/"):
         fileList = f[2] 
         break 

      # rating is at position 7 
      fileClass = []
      for f in fileList:
         if int(f[7]) == 1:
            fileClass.append("-")
         elif int(f[7]) == 5:
            fileClass.append("+")
         else:
            return "something weird happened"

      total = len(fileClass)
      indexes = range(0, total)
      foldGroups = range(folds)
      groups = []
      groupSize = total/folds    # each group will be of size groupSize

      # make the groups
      for i in foldGroups:
         g = random.sample(indexes, groupSize) # randomly put 'groupSize' reviews in a group
         indexes = [x for x in indexes if x not in g] # remove them
         groups.append(g)

      posPrecisions = []
      posRecalls = []
      negPrecisions = []
      negRecalls = []

      # training and testing   
      for i in foldGroups:
         # TRAIN - make the NEW old dictionary
         trains = [x for x in foldGroups if x != i]
         # iterate thru all the groups in trains
         for tg in trains:
            currentTrainGroup = groups[tg]
            for gi in currentTrainGroup:
               fileName = "reviews/" + fileList[gi]
               review = self.loadFile(fileName)
               words = self.tokenize(review)
               
               if fileClass[gi] == '-':
                  for word in words:
                     if word in self.negd:
                        self.negd[word] = self.negd[word] + 1
                     else:
                        self.negd[word] = 1
               elif fileClass[gi] == '+':
                  for word in words:
                     if word in self.posd:
                        self.posd[word] = self.posd[word] + 1
                     else:
                        self.posd[word] = 1
               else:
                  return "something weird happened 2"

         # and then make the filtered NEW old dictionary
         self.train_new()

         print "len(pos_filtered):", len(self.posNew)
         print "len(neg_filtered):", len(self.negNew)
         print "len(pos):", len(self.posd)
         print "len(neg):", len(self.negd)

         # TEST
         currentTestGroup = groups[i]
         pac = 0
         nac = 0
         ptc = 0
         ntc = 0

         for gi in currentTestGroup:
            fileName = "reviews/" + fileList[gi]
            review = self.loadFile(fileName)

            truth = fileClass[gi]
            result = self.classify(review) # this uses the NEW old dictionary plus the filtered NEW old dictionary

            if truth == "+":
               ptc = ptc + 1 
               if result == "positive" or result == "positive/neutral":
                  pac = pac + 1
            elif truth == "-": 
               ntc = ntc + 1
               if result == "negative" or result == "negative/neutral":
                  nac = nac + 1
            else:
               return "something weird happened 3"

         posPrecision = pac / float(groupSize)
         posPrecisions.append(posPrecision)
         posRecall = pac / float(ptc) 
         posRecalls.append(posRecall)
         negPrecision = nac / float(groupSize)
         negPrecisions.append(negPrecision)
         negRecall = nac / float(ntc)
         negRecalls.append(negRecall)

         # resets, so that a new dictionary can be built in the next iteration
         self.posd.clear()
         self.negd.clear()

      # report results
      pp = sum(posPrecisions) / len(posPrecisions)
      pr = sum(posRecalls) / len(posRecalls)
      negp = sum(negPrecisions) / len(negPrecisions)
      negr = sum(negRecalls) / len(negRecalls)
      print "pos precision:", pp
      print "pos recall: ", pr
      print "pos f-measure: ", (2*pp*pr)/(pp+pr)
      print "neg precision:", negp
      print "neg recall: ", negr
      print "neg f-measure: ", (2*negp*negr)/(negp+negr)
      return "done"

   def loadFile(self, sFilename):
      """Given a file name, return the contents of the file as a string."""

      f = open(sFilename, "r")
      sTxt = f.read()
      f.close()
      return sTxt
   
   def save(self, dObj, sFilename):
      """Given an object and a file name, write the object to the file using pickle."""

      f = open(sFilename, "w")
      p = pickle.Pickler(f)
      p.dump(dObj)
      f.close()
   
   def load(self, sFilename):
      """Given a file name, load and return the object stored in the file."""

      f = open(sFilename, "r")
      u = pickle.Unpickler(f)
      dObj = u.load()
      f.close()
      return dObj

   # slighly modified to filter out punctuation
   def tokenize(self, sText): 
      """Given a string of text sText, returns a list of the individual tokens that 
      occur in that string (in order)."""

      lTokens = []
      sToken = ""
      for c in sText:
         if re.match("[a-zA-Z0-9]", str(c)) != None: 
            sToken += c
         else:
            if sToken != "":
               lTokens.append(sToken.lower())
               sToken = ""
            if c.strip() != "" and re.match("[\w]", c.strip()) != None:
               lTokens.append(str(c.strip()))
               
      if sToken != "" and sToken != ".":
         lTokens.append(sToken.lower())

      return lTokens
