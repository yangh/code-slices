#lang racket
;Multiples of 3 and 5
;Problem 1
;
;If we list all the natural numbers below 10 that are multiples of 3 or 5,
;we get 3, 5, 6 and 9. The sum of these multiples is 23.
;
;Find the sum of all the multiples of 3 or 5 below 1000.

(define (sum-multi35 n sum)
  (cond
    [(eq? n 0) sum]
    [(or (eq? (remainder n 3) 0)
         (eq? (remainder n 5) 0))
     (sum-multi35 (sub1 n) (+ n sum))]
    [else (sum-multi35 (sub1 n) sum)]))

(sum-multi35 9 0)
(sum-multi35 999 0)