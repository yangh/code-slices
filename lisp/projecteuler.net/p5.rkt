#lang racket

(require "euler.rkt")

(define max (add1 20))

(define (is-factor? n lst)
  ;(displayln (format "~a in ~a" n lst))
  (cond
    [(empty? lst) #f]
    [(eq? (remainder (car lst) n) 0) #t]
    [else (is-factor? n (cdr lst))]))

(define singles (filter (lambda (n)
                          (not (is-factor? n (range (add1 n) max))))
                        (range 2 max)))
(displayln singles)
(define base (foldl * 1 singles))

(define (is-multiple? n x)
  (let loop ([i 2])
    (cond
      [(> i x) #t]
      [(eq? (remainder n i) 0)
       ;(displayln (format "Evenly div ~a" i))
       (loop (add1 i))]
      [else #f])))

(displayln (format "Base ~a" base))
(let loop ([n base]
           [lst (reverse singles)])
  (cond
    [(empty? lst) n]
    [(is-multiple? n 20)
     (displayln (format "Find n/~a ~a" (car lst) n))
     (loop (quotient n (car lst)) lst)
     ]
    [else
     (displayln (format "Last ~a" n))
     (loop n (cdr lst))
     ]))