#lang racket

(provide gen-color)

(define (gen-color [alpha #f])
  (let ([cmax 768]
        [cstep 1])
    (for/list ([i (in-range 0 cmax cstep)])
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
            (list 255 r g b)
            (list r g b))))
    ))

(define (nround n x)
  (cond
    [(> x 0)
     (let loop ([y x])
       (cond
         [(<= y n) (round y)]
         [else
          (loop (- y n))]))]
    [else (nround n (abs x))]))

(define (gen-gradient num c1 c2)
  (define-values (r1 g1 b1) (apply values c1))
  (define-values (r2 g2 b2) (apply values c2))
  (define rs (/ (- r2 r1) num))
  (define gs (/ (- g2 g1) num))
  (define bs (/ (- b2 b1) num))
  (for/list ([i num])
    (list (nround 255 (+ r1 (* i rs)))
          (nround 255 (+ g1 (* i gs)))
          (nround 255 (+ b1 (* i bs))))))

(module+ main
  (require slideshow/pict)

  (define (rainbow p color-list)
    (map (lambda (color)
           ;(displayln color)
           (colorize p color))
         color-list))

  (define (square n)
    (filled-rectangle n n))

  ;(rainbow (square 3) (gen-color))
  (rainbow (square 3) (gen-gradient 255 (list 1 1 1) (list 255 255 255)))
  (rainbow (square 3) (gen-gradient 255 (list 1 15 207) (list 255 0 25)))
  ;(displayln x)
  )
