#lang racket/gui

(require racket/date)

(define start-ts (current-seconds))

(define (printts)
  (let ([ts (current-seconds)])
    (printf "Time elapsed: ~a\n" (- ts start-ts))
    (set! start-ts ts)))

(define (gen-color [alpha #f])
  (let ([cs '()]
        [cmax 255]
        [cstep 1])
    (for ([r (in-range 0 cmax cstep)]
          [g (in-range 0 cmax cstep)]
          [b (in-range 0 cmax cstep)])
      (if alpha
          (set! cs (cons (list 255 r 0 0) cs))
          (set! cs (cons (list r 0 0) cs))))
    ;cs
    (reverse cs) 
    ;(append (reverse cs) cs)
    ))


(define m-width 60)
(define m-height 50)
(define bpp 4)
(define colors (gen-color #t))


(define (iterations a z i)
  (define z′ (+ (* z z) a))
  (define magn (magnitude z′))
  (if (or (= i 255) (> magn 2))
      (values i (- (+ i 1) (/ (log (log magn)) (log 2))))
      (iterations a z′ (add1 i))))

(define (mod n m)
    (if (< n m)
        (inexact->exact (round n))
        (mod (- n m) m)))

(define (iter->argb* i magn)
  (define a 255)
  (if (= i 255)
      (list a 255 255 255)
      (list a (mod (* magn 254) 254))
      ;(list-ref colors (mod magn 254))
      ;(list a 0 0 0)
      ;(list a (* 5 (modulo i 15)) (* 32 (modulo i 7)) (* 8 (modulo i 31)))
      )
  )

(define (argb-fill data argb pos)
  (define cpos (* pos bpp))
  (for ([c argb]
        [i (in-range bpp)])
    (bytes-set! data (+ cpos i) c)
    ;(when (< cpos 200) (displayln cpos))
    ))

(define o (open-output-string))
(define (oprint o . var)
  (lambda (o vars)
    (print vars o)
    (print "\n" o)))

(define (mandelbrot2 width height)
  ;(define target (make-object bitmap% width height #f #t))
  (define m-bytes* (make-bytes (* width height bpp)))

  (for* ([y height] [x width])
    (define real-x (- (* 3.0 (/ x width)) 2.25))
    (define real-y (- (* 2.5 (/ y height)) 1.25))
    (define pos (+ (* width y) x))

    (let-values ([(iter magn) (iterations (make-rectangular real-x real-y) 0 0)])
      ;(oprint o x y iter magn)
      ;(printf "~a, ~a, ~a, ~a\n" x y iter magn)
      (argb-fill m-bytes* (iter->argb* iter magn) pos)))
  (printts)

  m-bytes*)

(define frame (new frame% [label "Mandelbrot"]
                   [width m-width]
                   [height m-height]
                   [alignment '(center center)]))

(define (create-m-bitmap w h)
  (make-object bitmap%  w h #f #t))

(define m-bitmap (create-m-bitmap m-width m-height))

(define (draw-mandelbrot dc)
  (send dc draw-bitmap m-bitmap 0 0))

(define viewer (new canvas% [parent frame]
                    [min-width m-width]
                    [min-height m-height]
                    [paint-callback
                     (lambda (canvas dc)
                      (draw-mandelbrot dc))]
                    ))

(define (update-mb width height [force #f])
  (send frame resize width height)
  
  (if (and (not force) (equal? m-width width) (equal? m-height height))
      (displayln "No change")
      (set! m-bitmap (create-m-bitmap width height))
      )
  (set! m-width width)
  (set! m-height height)
  
  (printts)
  (displayln "Start render data...")
  (define new-bytes* (mandelbrot2 width height))
  (printts)  
  (displayln "Start render bitmap...")
  (send m-bitmap set-argb-pixels 0 0 width height new-bytes*)
  (printts)
  
  (send viewer refresh-now)
  )

(update-mb m-width m-height #t)
(send frame show #t)

;(display (get-output-string o))

;(update-mb 90 60)
;(update-mb 180 120)
;(update-mb 600 400)