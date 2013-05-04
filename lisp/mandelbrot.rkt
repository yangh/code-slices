#lang racket/gui

(require racket/date)

(define start-ts (current-seconds))

(define (printts)
  (let ([ts (current-seconds)])
    (printf "Time elapsed: ~a\n" (- ts start-ts))
    (set! start-ts ts)))

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
    ))


(define m-width 600)
(define m-height 600)
(define bpp 4)
(define colors (gen-color #t))
(define P1 (make-rectangular 1 1.5))
(define P2 (make-rectangular -2 -1.5))
(define oldP1 P1)
(define oldP2 P2)

(define maxIteration 25)
(define escapeRadius 2)
(define logEscapeRadius (log escapeRadius))
(define m-viewer 1)

(define (color-idx C z i)
  (define zN (lambda (Z) (+ (* Z Z) C)))
  ;(set! z (zN z))
  ;(set! i (+ i 1))
  (define mu ( - i (/ (log (log (magnitude (zN z)))) logEscapeRadius)))
  (define idx (* (/ mu maxIteration) 768))
  ;(printf "idx: ~a\n" idx)
  (if (or (>= idx 768) (< idx 0))
      0
      (inexact->exact (round idx))))

(define (argb-fill data argb pos)
  (define cpos (* pos bpp))
  (for ([c argb]
        [i (in-range bpp)])
    (bytes-set! data (+ cpos i) c)
    ))

(require racket/future)
(define bloop 1)

(define (iterations C z i)
  (if (or (>= i maxIteration) (>= (magnitude z) escapeRadius))
      (values i z)
      (iterations C (+ (* z z) C) (add1 i))))

(define (mandelbrot2 width height)
  (define m-bytes* (make-bytes (* width height bpp)))
  (define x-step (/ (real-part (- P1 P2)) (sub1 width)))
  (define y-step (make-rectangular 0 (/ (imag-part (- P1 P2)) (sub1 height))))
  (define z P2)
  
  (for ([x width])
    (set! z (make-rectangular (+ (real-part z) x-step) (imag-part P1)))

    (for ([y height])
      (set! z (- z y-step))

      (let-values ([(iter Z) (iterations z z 0)])
        ;(printf "~a, ~a, ~a, ~a\n" x y iter magn)
        (define idx (if (< iter maxIteration)
                        (color-idx z Z iter)
                        0))
        (argb-fill m-bytes*
                   (list-ref colors idx)
                   (+ (* width y) x)))))
  m-bytes*)

(define frame (new frame% [label "Mandelbrot"]
                   [width m-width]
                   [height m-height]
                   [border 0]
                   [alignment '(center center)]))

(define (create-m-bitmap w h)
  (make-object bitmap%  w h #f #t))

(define m-bitmap (create-m-bitmap m-width m-height))

(define (draw-mandelbrot dc)
  (send dc draw-bitmap m-bitmap 0 0))

(define (update-viewer viewer)
  (printts)
  (displayln "Start render data...")
  (define new-bytes* (mandelbrot2 m-width m-height))
  (printts)  
  (displayln "Start render bitmap...")
  (send m-bitmap set-argb-pixels 0 0 m-width m-height new-bytes*)
  (printts)
  
  (send viewer refresh-now)
  )

(define (zoom in e)
  (let ([x (send e get-x)]
        [y (send e get-y)])
    ;(printf "~a, ~a, zoom ~a\n" x y in)
    (define diff (- P1 P2))
    (define p (+ P2 (make-rectangular (/ (* x (real-part diff)) (sub1 m-width))
                                (/ (* (- m-height y) (imag-part diff)) (sub1 m-height)))))
    (if in
        (set! diff (/ diff 8))
        (set! diff (* diff 1)))
    (set! P1 (+ p diff))
    (set! P2 (- p diff))
    (when (< maxIteration 255)
      (set! maxIteration (+ 20 maxIteration)))
    (update-viewer m-viewer)
    ))

(define canvas-box%
  (class canvas%
    (define/override (on-event e)
      (let ([e-type (send e get-event-type)])
        (cond 
          [(equal? e-type 'left-up) (zoom #t e)]
          [(equal? e-type 'right-up) (zoom #f e)]
          )
        ;(displayln e-type)
        ))
    (super-new)))

(set! m-viewer (new canvas-box% [parent frame]
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
  
  (update-viewer m-viewer)
  )

(update-mb m-width m-height #t)
(send frame show #t)

;(display (get-output-string o))

;(update-mb 90 60)
;(update-mb 180 120)
;(update-mb 600 400)
