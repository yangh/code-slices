#lang slideshow

(define (gen-color [alpha #f])
  (let ([cs '()]
        [cmax 768]
        [cstep 1])
    (for ([i (in-range 0 cmax cstep)])
      (let-values ([(r g b) (values 0 0 0)])
        (cond 
          [(>= i 512)
           (set! r (- i 512))
           (set! g (- 255 r))]
          [(>= i 256)
           (set! g (- i 256))
           (set! b (- 255 g))]
          [else
           (set! b i)])
        (if alpha
            (set! cs (cons (list 255 r g b) cs))
            (set! cs (cons (list r g b) cs)))))
    ;cs 
    (reverse cs)
    ;(append (reverse cs) cs)
    ))

(define (rainbow p)
  (map (lambda (color)
         (displayln color)
         (colorize p color)
         )
       ;(list "red" "orange" "yellow" "green" "blue" "purple")
       (gen-color)))

(define (square n)
  (filled-rectangle n n))

(rainbow (square 3))

