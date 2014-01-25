#lang racket

(define (multip-of n b)
  (equal? (remainder n b) 0))

(define (fizzbuzz)
  (define marked #f)
  (for ([n (range 1 101)])
    (set! marked #f)
    (when (multip-of n 3)
      (display "Fizz")
      (set! marked #t))
    (when (multip-of n 5)
      (display "Buzz")
      (set! marked #t))
    (cond
      [marked (displayln "")]
      [else (displayln n)])))

(define (fizzbuzz1)
  (for ([n (range 1 101)])
    (cond
      [(and (multip-of n 3)
            (multip-of n 5))
       (displayln "FizzBuzz")]
      [(multip-of n 3)
       (displayln "Fizz")]
      [(multip-of n 5)
       (displayln "Buzz")]
      [else
       (displayln n)])))

(fizzbuzz1)
