#lang slideshow

(define (gen-color [alpha #f])
  (let ([cs '()]
        [cmax 255]
        [cstep 1])
    (for ([r (in-range 0 cmax cstep)]
          [g (in-range 0 cmax cstep)]
          [b (in-range 0 cmax cstep)])
      (if alpha
          (set! cs (cons (list 0 r 0 0) cs))
          (set! cs (cons (list r 0 0) cs))))
    ;cs 
    (reverse cs)
    ;(append (reverse cs) cs)
    ))

(define (rainbow p)
  (map (lambda (color)
         (colorize p color))
       ;(list "red" "orange" "yellow" "green" "blue" "purple")
       (gen-color)))

(define (square n)
  (filled-rectangle n n))

(rainbow (square 3))

