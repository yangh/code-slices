#lang racket

(require racket/future)

(define (bloop id n)
  (printf "bloop start ~a\n" id)
  (for ([i (in-range n)]) (- 0 i)))

;(let ([bloop2 (future (lambda () (bloop 1 1000000)))])
;  (list (bloop 2 1000000) (touch bloop2)))

(define (ls) 
  (let ([v '()])
    (for* ([x 700]
       [y 700])
      (set! v (cons (list x y) v)))
    v))

(require racket/flonum)

(define (mandelbrot iterations x y n)
  (let ([ci (fl- (fl/ (* 2.0 (->fl y)) (->fl n)) 1.0)]
        [cr (fl- (fl/ (* 2.0 (->fl x)) (->fl n)) 1.5)])
    (let loop ([i 0] [zr 0.0] [zi 0.0])
      (if (> i iterations)
          i
          (let ([zrq (fl* zr zr)]
                [ziq (fl* zi zi)])
            (cond
              [(fl> (fl+ zrq ziq) 4.0) i]
              [else (loop (add1 i)
                          (fl+ (fl- zrq ziq) cr)
                          (fl+ (fl* 2.0 (fl* zr zi)) ci))]))))))

(require racket/date)
(define start-ts (current-milliseconds))
(define (printts [reset #f])
  (define ts (current-milliseconds))
  (when (not reset)
    (printf "Time elapsed: ~ams\n" (- ts start-ts)))
  (set! start-ts ts))

(define maxIter 10000000)

(displayln "Single loop")
(mandelbrot maxIter 62 500 1000)
(printts)

;(list (mandelbrot maxIter 62 501 1000)
;      (mandelbrot maxIter 62 500 1000))
;(printts)

(displayln "Two loop with future")
(let ([f (future (lambda () (mandelbrot maxIter 62 501 1000)))])
  (list (mandelbrot maxIter 62 500 1000)
        (touch f)))
(printts)