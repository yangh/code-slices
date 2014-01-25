#lang racket

(provide is-prime?)

(define (is-prime? p)
  (cond
    [(member p (list 1 2 3 5)) #t]
    [(even? p) #f]
    [(eq? (remainder p 3) 0) #f]
    [(eq? (remainder p 5) 0) #f]
    [else
     (let find ([a 7])
       (cond
         [(eq? p a) #t]
         [(eq? (remainder p a) 0) #f]
         [else (find (+ a 2))]))]))