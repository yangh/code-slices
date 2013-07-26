#lang racket

(define max 4000000)

(define (sum-even-fib f1 f2 sum)
  ;(displayln (format "~a ~a ~a" f1 f2 sum))
  (cond
    [(> f2 max) sum]
    [(even? f2)
     (sum-even-fib f2 (+ f1 f2) (+ f2 sum))]
    [else
     (sum-even-fib f2 (+ f1 f2) sum)]))

(sum-even-fib 1 2 0)