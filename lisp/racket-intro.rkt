
#lang slideshow
(define c (circle 18))
(define r (rectangle 20 30))

(define (square n)
  (filled-rectangle n n))

(define (four p)
  (define two-p (hc-append p p))
  (vc-append two-p two-p))

(define (checker p1 p2)
  (let ([p12 (hc-append p1 p2)]
        [p21 (hc-append p2 p1)])
    (vc-append p12 p21)))

(define (checkerboard p)
  (let* ([rp (colorize p "red")]
         [bp (colorize p "black")]
         [c (checker rp bp)]
         [c4 (four c)])
    (four c4)))

;;(checkerboard (square 10))

(define (series mk)
  (hc-append 4 (mk 5) (mk 10) (mk 20)))

;;(series (lambda (size) (checkerboard (square size))))

(define (rgb-series mk)
  (vc-append
   (series (lambda (sz) (colorize (mk sz) "red")))
   (series (lambda (sz) (colorize (mk sz) "green")))
   (series (lambda (sz) (colorize (mk sz) "blue")))))


(define (bake flavor)
  (printf "pre-heatingoven...\n")
  (string-append flavor " pie"))

(define (mmx a b)
  (if (> a b) a b))

(define (remove-dups l)
  (cond
    [(empty? l) empty]
    [(empty? (rest l)) l]
    [else
     (let ([i (first l)])
       (if (equal? i (list-ref l 1))
           (remove-dups (rest l))
           (cons i (remove-dups (rest l)))))]))
