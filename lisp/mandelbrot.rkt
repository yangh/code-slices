#lang racket/gui

(require racket/date)

(define start-ts (current-seconds))

(define (printts)
  (let ([ts (current-seconds)])
    (printf "Time elapsed: ~a\n" (- ts start-ts))
    (set! start-ts ts)))

(define (iterations a z i)
  (define z′ (+ (* z z) a))
  (if (or (= i 255) (> (magnitude z′) 2))
      i
      (iterations a z′ (add1 i))))
 
(define (iter->argb* i)
  (define a 255)
  (if (= i 255)
      (list a 255 255 255)
      (list a (* 5 (modulo i 15)) (* 32 (modulo i 7)) (* 8 (modulo i 31)))))
 
(define (argb-fill data argb pos)
  (define cpos (* pos 4))
  (for ([c argb]
        [i (in-range 4)])
    (bytes-set! data (+ cpos i) c)
    ;(when (< cpos 200) (displayln cpos))
    ))

(define m-width 180)
(define m-height 120)

(define (mandelbrot2 width height)
  (define target (make-object bitmap% width height #f #t))
  (define m-bytes* (make-bytes (* width height 4)))
 
  (for* ([x width] [y height])
    (define real-x (- (* 3.0 (/ x width)) 2.25))
    (define real-y (- (* 2.5 (/ y height)) 1.25))
    (define pos (+ (* width y) x))
    ;(displayln pos)
    (argb-fill m-bytes* (iter->argb* (iterations (make-rectangular real-x real-y) 0 0)) pos))
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

;(update-mb 90 60)
;(update-mb 180 120)
;(update-mb 600 400)