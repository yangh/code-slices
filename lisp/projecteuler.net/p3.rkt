#lang racket

(define (is-prime? p)
  (cond
    [(even? p) #f]
    [(eq? (remainder p 3) 0) #f]
    [(eq? (remainder p 5) 0) #f]
    [else
     (let find ([a 7])
       (cond
         [(eq? p a) #t]
         [(eq? (remainder p a) 0) #f]
         [else (find (+ a 2))]))]))

(define (next-prime g)
  (let loop ([n (+ g 1)])
    (cond
      [(is-prime? n) n]
      [else loop (+ n 1)])))

(define (max-prime-factor n guess)
  (cond
    [(> guess (quotient n 2)) displayln "Out of range"]
    [(eq? (remainder n guess) 0)
     (displayln guess)
     (max-prime-factor n (next-prime guess))
     ]
    [else
     (max-prime-factor n (next-prime guess))]))

(max-prime-factor 600851475143 2)