#lang plai/gc2/collector
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

(print-only-errors)

;; eecs 321 hw #7 
;; author: yi (melody) yin
;; date: march 6th, 2015

;; **********
;; init-allocator : -> void
;; creates a heap of size heap-size
;; with the first 4 spaces reserved for ~special~ state variables
(define (init-allocator)
  (init-alloc-pointer)
  (init-active-space)
  (init-q-start)
  (init-q-end)
  (for ([i (in-range 4 (heap-size))])
    (heap-set! i 'free)))

;; start loc of the semi-space
(define (semi-start) 
  (ceiling (/ (+ 4 (heap-size)) 2)))

;; get/set state variables 
;; -----------------------------------------------------------------------------
;; alloc-pointer starts at 4
;; can be any number in range 4 (heap-size)
(define (init-alloc-pointer) 
  (heap-set! 0 4))
(define (alloc-pointer)
  (heap-ref 0))
;; alloc-pointer increments until it is larger than heap-size, then starts over
(define (set-ap sz)
  (let ([new-ap (+ (alloc-pointer) sz)])
    (cond 
      [(> new-ap (heap-size))
       (heap-set! 0 (+ 4 (- new-ap (heap-size))))]
      [else (heap-set! 0 new-ap)])))

(define (set-ap2 new-val)
  (heap-set! 0 new-val))
    
;; active-space starts at the top half (4)
;; can be two values: 4 OR semi-space
(define (init-active-space)
  (heap-set! 1 4))
(define (active-space)
  (heap-ref 1))
(define (set-as new-x)
  (heap-set! 1 new-x))

;; q-start and q-end 
(define (init-q-start)
  (heap-set! 2 (semi-start)))
(define (q-start)
  (heap-ref 2))
(define (set-qs new-x)
  (heap-set! 2 new-x))
(define (init-q-end)
  (heap-set! 3 (q-start)))
(define (q-end)
  (heap-ref 3))
(define (set-qe new-x)
  (heap-set! 3 new-x))

;; -----------------------------------------------------------------------------

;; not from slides
;; -----------------------------------------------------------------------------
;; find-free-space : location integer -> location or #f
;; starting at location start, find the first integer size cells of free space
;; if there is enough space, return location 
;; otherwise #f
(define (find-free-space start size)
  (cond 
    [(= start (heap-size)) #f]
    [else
     (case (heap-ref start)
       [(fwd)
        (case (heap-ref (heap-ref (+ start 1))) ; check what tag it is
          [(flat) (find-free-space (+ start 2) size)]
          [(pair) (find-free-space (+ start 3) size)]
          [(proc) (find-free-space (+ start 3 (heap-ref (+ start 2))) size)]
          [else 
           (error 'find-free-space "fwd pointer wrong ~s" (heap-ref (+ start 1)))])] 
       [(free) (if (n-free-blocks? start size) start
                   (find-free-space (+ start 1) size))] 
       [(flat) (find-free-space (+ start 2) size)]
       [(pair) (find-free-space (+ start 3) size)]
       [(proc) 
        (find-free-space (+ start 3 (heap-ref (+ start 2))) size)]
       [else (error 'find-free-space "not a tag ~s" (heap-ref start))])]))

;; alloc-flat : heap-value -> location
;; allocates flat value and returns the location
;; error if insufficient space 
(define (gc:alloc-flat fv)
  (let ([pos (alloc 2 '() '())])
    (heap-set! pos 'flat)
    (heap-set! (+ pos 1) fv)
    (set-ap 2) pos))

;; cons : root root -> location
;; allocates cons cell on the heap
(define (gc:cons hd tl)
  (let ([pos (alloc 3 hd tl)])
    (heap-set! pos 'pair)
    (heap-set! (+ pos 1) (read-root hd))
    (heap-set! (+ pos 2) (read-root tl))
    (set-ap 3) pos))

;; closure : heap-value (listof root) -> location
;; 'proc | code-ptr | count | var1 | var2 ... 
(define (gc:closure code-ptr free-vars)
  (define free-vars-count (length free-vars))
  (define next (alloc (+ free-vars-count 3) free-vars '()))
  (heap-set! next 'proc)
  (heap-set! (+ next 1) code-ptr)
  (heap-set! (+ next 2) free-vars-count)
  (for ([x (in-range 0 free-vars-count)]
        [r (in-list free-vars)])
    (heap-set! (+ next 3 x) (read-root r)))
  (set-ap (+ free-vars-count 3)) next)

;; alloc : integer root root -> location or error
;; if alloc-pointer will be pointing at beginning of new space or heap-size+1, collect
;; ow, return the location
(define (alloc n one-root two-root)
  (let ([next (find-free-space (active-space) n)])
    (cond
      ; first half is active
      [(and (= (active-space) 4)
            (> (+ n (alloc-pointer)) 
                (semi-start)))
       (set-ap2 (semi-start))
       (collect-garbage one-root two-root)
       ; now second half is active
       (let ([next (find-free-space (semi-start) n)]) 
         (unless next 
           (error 'alloc "out of space")) next)]
      ; second half is active, but full 
      [(and (= (active-space) (semi-start))
            (> (+ n (alloc-pointer)) 
               (heap-size)))
       (set-ap2 (heap-size))
       (collect-garbage one-root two-root)
       ; now first half is active
       (let ([next (find-free-space 4 n)])
         (unless next ; if next = #f
           (error 'alloc "out of space")) next)]
      [else next])))

;; collect-garbage : root root -> void
(define (collect-garbage one-root two-root)
  (validate-heap)
  (send/roots one-root)
  (send/roots two-root)
  (send/roots (get-root-set))
  (traverse/roots one-root)
  (traverse/roots two-root)
  (traverse/roots (get-root-set))
  (copy-over)
  (validate-heap))

;; send/roots : root -> void
(define (send/roots rt)
  (cond
    [(list? rt) (for-each send/roots rt)]
    [(root? rt) (send/roots (read-root rt))]
    [(number? rt) (send-to-active-space rt)]))

;; send-to-active-space : root -> void (but heap changed)
;; copies the root pointers and contents into the new space
;; replaces prev locs with 'fwd tag and new locs in old space
;; moves the q-end as it copies over
(define (send-to-active-space rt)
  (cond 
    [(empty? rt) (void)]
    [else
     (define loc (get-loc rt))
     (define len (length-at loc))
     (cond 
       ; already in queue
       [(or (= len 99)
            (and (= (active-space) 4) 
             (> rt (semi-start)))
            (and (= (active-space) (semi-start))
                 (> rt (heap-size))))
        (void)]
       ; need to move into queue
       [else 
        (for ([i (in-range 0 (+ 1 len))])
          (heap-set! (+ i (q-end)) (heap-ref (+ i loc))))
        (heap-set! loc 'fwd) 
        (heap-set! (+ 1 loc) (q-end))
        (set-ap (+ len 1))
        (set-qe (+ (q-end) len 1))])])) 

;; get-loc : (or/c root? location?) -> location
;; returns the location
(define get-loc (lambda (x) 
                  (if (root? x) (read-root x) x)))

;; length-at : location -> integer 
;; gets the length AFTER the tag 
(define (length-at loc) 
  (case (heap-ref loc)
    [(flat) 1]
    [(pair) 2]
    ((proc) (+ 2 (heap-ref (+ loc 2))))
    [(free) 0]
    [(fwd) 99]
    [else (error "something wrong at" loc)]))

;; traverse/roots : root -> void
(define (traverse/roots rt)
  (cond
    [(list? rt) (for-each traverse/roots rt)]
    [(root? rt) (set-root! rt (heap-ref (+ (read-root rt) 1)))
                (traverse/roots (read-root rt))]
    [(number? rt) (traverse/loc rt)]))

;; traverse/loc : location -> void 
;; if encounter a pointer, change the address (already should be in queue)
;; moves the q-start until it is equal to q-end
(define (traverse/loc loc)
  (define len (length-at loc)) 
  (cond 
    [(= (q-start) (q-end)) (void)]
    [else
     (case (heap-ref loc)
       [(flat) (set-qs (+ 2 (q-start)))
               (traverse/loc (q-start))]
       [(pair) (send-to-active-space (heap-ref (+ loc 1)))
               (send-to-active-space (heap-ref (+ loc 2)))
               (cond 
                 [(equal? (heap-ref (heap-ref (+ loc 1))) 'fwd) 
                  (heap-set! (+ loc 1) (heap-ref (+ 1 (heap-ref (+ loc 1)))))])
               (cond 
                 [(equal? (heap-ref (heap-ref (+ loc 2))) 'fwd)
                  (heap-set! (+ loc 2) (heap-ref (+ 1 (heap-ref (+ loc 2)))))])
               (set-qs (+ 3 (q-start)))
               (traverse/loc (q-start))]
       [(proc) (for ([x (in-range 3 (+ 3 (heap-ref (+ loc 2))))])
                 (send-to-active-space (heap-ref (+ loc x)))
                 (cond
                   [(equal? (heap-ref (heap-ref (+ loc x))) 'fwd) 
                    (heap-set! (+ loc x) 
                               (heap-ref (+ 1 (heap-ref (+ loc x)))))]))
               (set-qs (+ 3 loc (heap-ref (+ loc 2))))
               (traverse/loc (q-start))]
       [(free) (void)]
       [else (error 'traverse/loc "nope @ loc ~s" (heap-ref loc))])]))

;; copy-over
(define (copy-over)
  (cond
    [(= 4 (active-space)) (free-top)
                          (set-as (semi-start))
                          (set-qs 4)
                          (set-qe 4)]
    [else (free-bottom)
          (init-active-space)
          (init-q-start)
          (init-q-end)]))

;; speaks for itself
(define (free-top)
  (for ([i (in-range 4 (semi-start))])
    (heap-set! i 'free)))

;; again
(define (free-bottom)
  (for ([i (in-range (semi-start) (heap-size))])
    (heap-set! i 'free)))

;; tests 
;; making sure all the allocs work.. filled up first space
(test (let ([hp (make-vector 32)])
        (with-heap hp (init-allocator)
                   (gc:alloc-flat 10)
                   (gc:alloc-flat 20)
                   (gc:cons (simple-root 4) (simple-root 4))
                   (gc:closure 999 `{,(simple-root 4) ,(simple-root 6)})
                   (gc:alloc-flat 30) hp))
      (vector 18 4 18 18 
              'flat 10 'flat 20 'pair 4 4 
              'proc 999 2 4 6 'flat 30 
              'free 'free 'free 'free 'free 'free 'free 
              'free 'free 'free 'free 'free 'free 'free))
;; 2 roots - cons with flat flat
(test (let ([hp (make-vector 32)])
        (with-heap hp (init-allocator)
                   (gc:alloc-flat 10)
                   (gc:alloc-flat 20)
                   (gc:cons (simple-root 4) (simple-root 4))
                   (gc:closure 999 `{,(simple-root 4) ,(simple-root 6)})
                   (gc:alloc-flat 30) 
                   (gc:cons (simple-root 4) (simple-root 6)) hp))
      (vector 25 18 4 4 
              'free 'free 'free 'free 'free 'free 'free
              'free 'free 'free 'free 'free 'free 'free
              'flat 10 'flat 20 'pair 18 20
              'free 'free 'free 'free 'free 'free 'free))
;; 2 roots - cons with flat cons
(test (let ([hp (make-vector 32)])
        (with-heap hp (init-allocator)
                   (gc:alloc-flat 10)
                   (gc:alloc-flat 20)
                   (gc:cons (simple-root 4) (simple-root 4))
                   (gc:closure 999 `{,(simple-root 4) ,(simple-root 6)})
                   (gc:alloc-flat 30) 
                   (gc:cons (simple-root 4) (simple-root 8)) hp))
      (vector 26 18 4 4
              'free 'free 'free 'free 'free 'free 'free
              'free 'free 'free 'free 'free 'free 'free
              'flat 10 'pair 18 18 'pair 18 20 
              'free 'free 'free 'free 'free 'free))
;; 2 roots - cons with cons cons 
(test (let ([hp (make-vector 32)])
        (with-heap hp (init-allocator)
                   (gc:alloc-flat 10)
                   (gc:alloc-flat 20)
                   (gc:cons (simple-root 4) (simple-root 4))
                   (gc:closure 999 `{,(simple-root 4) ,(simple-root 6)})
                   (gc:alloc-flat 30) 
                   (gc:cons (simple-root 8) (simple-root 8)) hp))
      (vector 26 18 4 4
              'free 'free 'free 'free 'free 'free 'free
              'free 'free 'free 'free 'free 'free 'free
              'pair 21 21 'flat 10 'pair 18 18 
              'free 'free 'free 'free 'free 'free))
;; 2 roots - cons with proc cons
(test/exn (let ([hp (make-vector 32)])
        (with-heap hp (init-allocator)
                   (gc:alloc-flat 10)
                   (gc:alloc-flat 20)
                   (gc:cons (simple-root 4) (simple-root 4))
                   (gc:closure 999 `{,(simple-root 4) ,(simple-root 6)})
                   (gc:alloc-flat 30) 
                   (gc:cons (simple-root 11) (simple-root 8)) hp)) "alloc")
;; 2 roots - cons with proc proc 
(test (let ([hp (make-vector 32)])
        (with-heap hp (init-allocator)
                   (gc:alloc-flat 10)
                   (gc:alloc-flat 20)
                   (gc:cons (simple-root 4) (simple-root 4))
                   (gc:closure 999 `{,(simple-root 4) ,(simple-root 6)})
                   (gc:alloc-flat 30) 
                   (gc:cons (simple-root 11) (simple-root 11)) hp))
      (vector 30 18 4 4 
              'free 'free 'free 'free 'free 'free 'free
              'free 'free 'free 'free 'free 'free 'free
              'proc 999 2 23 25 'flat 10 'flat 20 'pair 18 18 'free 'free))
;; 2 roots - proc with cons cons
(test (let ([hp (make-vector 32)])
          (with-heap hp (init-allocator)
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 8) ,(simple-root 8)}) hp))
      (vector 28 18 4 4
              'free 'free 'free 'free 'free 'free 'free
              'free 'free 'free 'free 'free 'free 'free
              'pair 21 21 'flat 10 'proc 'something 2 18 18 
              'free 'free 'free 'free))
;; 2 roots - proc with flat flat 
(test (let ([hp (make-vector 32)])
        (with-heap hp (init-allocator)
                   (gc:alloc-flat 10)
                   (gc:alloc-flat 20)
                   (gc:cons (simple-root 4) (simple-root 4))
                   (gc:closure 999 `{,(simple-root 4) ,(simple-root 6)})
                   (gc:alloc-flat 30) 
                   (gc:closure 999 `{,(simple-root 4) ,(simple-root 6)}) hp))
      (vector 27 18 4 4 
              'free 'free 'free 'free 'free 'free 'free 
              'free 'free 'free 'free 'free 'free 'free 
              'flat 10 'flat 20 'proc 999 2 18 20 
              'free 'free 'free 'free 'free))
;; 2 roots - proc with roots: proc proc
;; start over
(test (equal?
       (let ([hp (make-vector 32)])
          (with-heap hp (init-allocator)
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 11) ,(simple-root 11)}) hp))
       (let ([hp (make-vector 32)])
          (with-heap hp (init-allocator)
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 11) ,(simple-root 11)})
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 11) ,(simple-root 11)}) hp))) #t)
;; 2 roots - proc with roots: flat proc
;; starting over
(test (equal?
       (let ([hp (make-vector 32)])
          (with-heap hp (init-allocator)
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 11)}) hp))
       (let ([hp (make-vector 32)])
          (with-heap hp (init-allocator)
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 11)})
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 11)}) hp))) #t)
;; 2 roots - proc with roots: cons proc
;; starting over
(test (equal? 
       (let ([hp (make-vector 38)])
          (with-heap hp (init-allocator)
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 8) ,(simple-root 11)}) hp))
       (let ([hp (make-vector 38)])
          (with-heap hp (init-allocator)
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 8) ,(simple-root 11)})
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 8) ,(simple-root 11)}) hp))) #t)
;; 2 roots - proc with roots: proc cons
;; starting over
(test (equal? 
       (let ([hp (make-vector 38)])
          (with-heap hp (init-allocator)
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 11) ,(simple-root 8)}) hp))
       (let ([hp (make-vector 38)])
          (with-heap hp (init-allocator)
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20)
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 11) ,(simple-root 8)})
                     (gc:alloc-flat 10)
                     (gc:alloc-flat 20) 
                     (gc:cons (simple-root 4) (simple-root 4))
                     (gc:closure 'something `{,(simple-root 4) ,(simple-root 6)})
                     (gc:alloc-flat 30) 
                     (gc:closure 'something `{,(simple-root 11) ,(simple-root 8)}) hp))) #t)