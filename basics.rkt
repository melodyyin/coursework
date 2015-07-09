#lang plai
;; honor code
(define eight-principles
  (list
   "Know your rights."
   "Acknowledge your sources."
   "Protect your work."
   "Avoid suspicion."
   "Do your own work."
   "Never falsify a record or permit another person to do so."
   "Never fabricate data, citations, or experimental results."
   "Always tell the truth when discussing your work with your instructor."))

;; eecs 321 hw #1 
;; author: yi (melody) yin
;; date: january 9th, 2015

;; **********
;; part 2 - Trees
;; smallest : Tree -> number 
;; returns the smallest number in a binary tree
(define-type Tree
  [leaf]
  [node (val number?)
        (left Tree?)
        (right Tree?)])

(define (smallest t)
  (type-case Tree t
    [leaf () +inf.0]
    [node (v l r) (first (sort (list v (smallest l) (smallest r)) <))]))

;; tests
(print-only-errors)
(test (smallest (leaf)) +inf.0) ; empty
(test (smallest (node 10 (leaf) (leaf))) 10) ; one node 
(test (smallest (node 10 (node 5 (leaf) (leaf)) (leaf))) 5) ; parent plus left child
(test (smallest (node 10 (leaf) (node 5 (leaf) (leaf)))) 5) ; parent plus right child
(test (smallest (node 10 (node 2 (leaf) (leaf)) (node 5 (leaf) (leaf)))) 2) ; parent with both children
(test (smallest (node 10 (node 11 (node 2 (leaf) (leaf)) (leaf)) (node 3 (leaf) (leaf)))) 2) ; one left subtree
(test (smallest (node 10 (node 11 (leaf) (node 2 (leaf) (leaf))) (node 3 (leaf) (leaf)))) 2) ; one right subtree 
(test (smallest (node 1 (node 11 (leaf) (node 2 (leaf) (leaf))) (node 3 (leaf) (leaf)))) 1) ; one right subtree, smallest is root

;; part 3 - Negate
;; negate : Tree -> Tree
;; returns tree with numbers negated
(define (negate t)
  (type-case Tree t
    [leaf () t]
    [node (v l r) (node (- 0 v) (negate l) (negate r))]))

;; tests
(test (negate (leaf)) (leaf)) ; empty 
(test (negate (node 10 (leaf) (leaf))) (node -10 (leaf) (leaf))) ; one node 
(test (negate (node 10 (node 11 (leaf) (leaf)) (leaf))) (node -10 (node -11 (leaf) (leaf)) (leaf))) ; parent plus left child
(test (negate (node 10 (leaf) (node 11 (leaf) (leaf)))) (node -10 (leaf) (node -11 (leaf) (leaf)))) ; parent plus right child
(test (negate (node 10 (node 11 (leaf) (leaf)) (node 12 (leaf) (leaf)))) (node -10 (node -11 (leaf) (leaf)) (node -12 (leaf) (leaf)))) ; parent with both children 
(test (negate (node 10 (node 11 (node 13 (leaf) (leaf)) (leaf)) (node 12 (leaf) (leaf))))
      (node -10 (node -11 (node -13 (leaf) (leaf)) (leaf)) (node -12 (leaf) (leaf)))) ; one left subtree 
(test (negate (node 10 (node 11 (leaf) (leaf)) (node 12 (node 14 (leaf)(leaf)) (leaf))))
      (node -10 (node -11 (leaf) (leaf)) (node -12 (node -14 (leaf) (leaf)) (leaf)))) ; one right subtree

;; part 4 - Contains?
;; contains : Tree number -> boolean
;; returns #t or #f depending on existence of number in tree 
(define (contains? t n)
  (type-case Tree t
    [leaf () #f]
    [node (v l r) (or (= v n) (contains? l n) (contains? r n))]))

;; tests
(test (contains? (leaf) 0) #f); empty
(test (contains? (node 10 (leaf) (leaf)) 10) #t); one node, exists
(test (contains? (node 10 (leaf) (leaf)) 11) #f); one node, does not exist
(test (contains? (node 10 (node 11 (leaf) (leaf)) (leaf)) 10) #t); left child, exists
(test (contains? (node 10 (node 11 (leaf) (leaf)) (leaf)) 12) #f); left child, does not exist
(test (contains? (node 10 (node 11 (leaf) (leaf)) (node 111 (leaf) (leaf))) 111) #t); two children, exists
(test (contains? (node 10 (node 11 (leaf) (leaf)) (node 111 (leaf) (leaf))) 112) #f); two children, does not exist

;; part 5 - Sorted?
;; sorted? : Tree -> boolean 
;; returns #t or #f depending on whether the inorder traversal returns increasing numbers or repeated numbers
(define (sorted? t)
  (type-case Tree t
    [leaf () #t]
    [node (v l r) (check t -inf.0 +inf.0)]))

;; helper function
(define (check t smaller larger)
  (type-case Tree t
    [leaf () #t]
    [node (v l r) 
          (cond 
            [(and (<= smaller v) (>= larger v)) (and (check l -inf.0 v) (check r v +inf.0))]
            [else #f]
            )])) 
  
;; tests
(test (sorted? (leaf)) #t) ; empty
(test (sorted? (node 10 (leaf) (leaf))) #t) ; one node
(test (sorted? (node 10 (node 9 (leaf) (leaf)) (leaf))) #t) ; left child, sorted
(test (sorted? (node 10 (node 11 (leaf) (leaf)) (leaf))) #f) ; left child, unsorted 
(test (sorted? (node 10 (leaf) (node 11 (leaf) (leaf)))) #t) ; right child, sorted
(test (sorted? (node 10 (leaf) (node 9 (leaf) (leaf)))) #f) ; right child, unsorted 
(test (sorted? (node 10 (node 9 (leaf) (leaf)) (node 11 (leaf) (leaf)))) #t) ; two children, sorted
(test (sorted? (node 10 (node 10 (leaf) (leaf)) (node 10 (leaf) (leaf)))) #t) ; two children, sorted
(test (sorted? (node 10 (node 11 (leaf) (leaf)) (node 12 (leaf) (leaf)))) #f) ; two children, unsorted
(test (sorted? (node 1 (node 11 (leaf) (leaf)) (node 12 (leaf) (leaf)))) #f) ; two children, unsorted 

;; part 6 - is-braun?
;; is-braun? : Tree -> boolean
;; returns #t or #f depending on whether it is a Braun tree
;; it is a Braun tree if: 
;; 1) it is a leaf 
;; 2) both children are Braun trees AND sizes are the same (leaf not a size)
;; 3) both children are Braun trees AND left subtree has one more element 
(define (is-braun? t)
  (type-case Tree t
    [leaf () #t]
    [node (v l r) (cheque t)]))

;; helper functions
(define (cheque t)
  (type-case Tree t
    [leaf () #t]
    [node (v l r) 
          (cond 
            [(and (leaf? l) (leaf? r)) #t]
            [(leaf? l) #f]
            [else 
             (and (>= (num-children l) (num-children r)) (and (cheque l) (cheque r)))]
            )]))

(define (num-children t)
  (type-case Tree t
    [leaf () 0]
    [node (v l r)
          (cond 
            [(and (leaf? l) (leaf? r)) 0]
            [(or (leaf? l) (leaf? r)) 1]
            [else 2])]))

;; tests
(test (is-braun? (leaf)) #t) ; empty 
(test (is-braun? (node 9 (leaf) (leaf))) #t) ; one node 
(test (is-braun? (node 9 (node 9 (leaf) (leaf)) (leaf))) #t) ; one left child 
(test (is-braun? (node 9 (leaf) (node 9 (leaf) (leaf)))) #f) ; one right child IS NOT
(test (is-braun? (node 9 (node 9 (leaf) (leaf)) (node 9 (leaf) (leaf)))) #t) ; both children
(test (is-braun? (node 9 (node 9 (node 9 (leaf) (leaf)) (leaf)) (node 9 (leaf) (leaf)))) #t) ; left size 2, right size 1 & left size 1, right size 0 
(test (is-braun? (node 9 (node 9 (leaf) (node 9 (leaf) (leaf))) (node 9 (leaf) (leaf)))) #f) ; left size 2, right size 1 & left size 0, right size 1 IS NOT 

;; part 7 - Making Braun Trees
;; make-sorted-braun : number -> Tree
;; returns a braun Tree of size number with node values {0,...,number-1}
(define (make-sorted-braun n)
  (cond 
    [(= n 0) (leaf)]
    [(odd? n)
     (node (median 0 (- n 1)) (make-sorted-braun (median 0 (- n 1))) (add (make-sorted-braun (median 0 (- n 1))) (+ (median 0 (- n 1)) 1)))]
    [(even? n)
     (node (median 0 (- n 1)) (make-sorted-braun (median 0 (- n 1))) (add (make-sorted-braun (- (median 0 (- n 1)) 1)) (+ (median 0 (- n 1)) 1)))]
    ))

;; helper functions
;; adds n to each node in t
(define (add t n)
  (type-case Tree t
    [leaf () t]
    [node (v l r) 
          (node (+ n v) (add l n) (add r n))]))

(define (median l r)
  (ceiling (/ (+ l r) 2)))

;; tests
(test (is-braun? (make-sorted-braun 10)) #t)
(test (sorted? (make-sorted-braun 10)) #t)
(test (= (smallest (make-sorted-braun 10)) 0) #t)
(test (= (smallest (negate (make-sorted-braun 10))) (- 1 10)) #t)

(test (make-sorted-braun 0) (leaf)) ; empty 
(test (make-sorted-braun 1) (node 0 (leaf) (leaf))) ; base case 1
(test (make-sorted-braun 2) (node 1 (node 0 (leaf) (leaf)) (leaf))) ; base case 2
(test (make-sorted-braun 3) (node 1 (node 0 (leaf) (leaf)) (node 2 (leaf) (leaf)))) ; base case 3 
(test (make-sorted-braun 4) (node 2 (node 1 (node 0 (leaf) (leaf)) (leaf)) (node 3 (leaf) (leaf)))) ; even size
(test (make-sorted-braun 5) (node 2 (node 1 (node 0 (leaf) (leaf)) (leaf)) (node 4 (node 3 (leaf) (leaf)) (leaf)))) ; odd size