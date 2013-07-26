#lang racket

(define (is-palindrome n)
  (define ns (number->string n))
  (define len (string-length ns))
  ;(displayln ns)
  (cond
    [(odd? len) #f]
    [else
     (let loop ([i 0])
       ;(displayln i)
       (cond
         [(eq? i (/ len 2)) #t]
         [(equal? (string-ref ns i)
                  (string-ref ns (- len i 1)))
          (loop (add1 i))]
         [else #f]))]))

(for* ([x (range 100 1000)]
       [y (range 100 1000)])
  (when (is-palindrome (* x y))
    (displayln (format "~a * ~a = ~a" x y (* x y)))
    (flush-output)))