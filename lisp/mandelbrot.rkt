#lang racket/gui

(require racket/date)

(define start-ts (current-milliseconds))

(define (printts [reset #f])
  (define ts (current-milliseconds))
  (define-values (q r) (quotient/remainder (- ts start-ts) 1000))
  (when (not reset)
    (printf "Time elapsed: ~a.~as\n" q r))
  (set! start-ts ts))

(define (gen-color [alpha #f])
  (define cs '())
  (define cmax 768)
  (define cstep 1)
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
  )

; Keep ratio with (- Q1 Q2)
(define m-width 325)
(define m-height 300)
(define bpp 4)
(define colors (gen-color #t))

(define std-Q1 (make-rectangular -2.25 1.5))
(define std-Q2 (make-rectangular 1 -1.5))
(define Q1 std-Q1)
(define Q2 std-Q2)

(define minimumIteration 25)
(define maximumIteration 500)
(define stepIteration 25)

; Current maximum iteration
(define maxIteration minimumIteration)

; Set as max part of Q1, Q2
(define escapeRadius 2.25)
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

(define (iterations c z i)
  (if (or (>= i maxIteration) (>= (magnitude z) escapeRadius))
      (values i z)
      (iterations c (+ (* z z) c) (add1 i))))

(define (mandelbrot2 width height)
  (define m-bytes* (make-bytes (* width height bpp)))
  (define x-step (make-rectangular (/ (abs (real-part (- Q1 Q2))) (sub1 width)) 0))
  (define y-step (make-rectangular 0 (/ (abs (imag-part (- Q1 Q2))) (sub1 height))))
  
  ;(printf "step (~a, ~a)\n" x-step y-step)
  (for ([ y height])
    (define y-inc (- Q1 (* y-step y)))
    (for ([x width])
      (define z (+ y-inc (* x-step x)))
      (define-values (iter Z) (iterations z z 0))

      (define idx 0)
      (define pos (+ (* width y) x))
      (when (< iter maxIteration)
        (set! idx (color-idx z Z iter)))
      (argb-fill m-bytes* (list-ref colors idx) pos))
      )
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
  (printts #t)
  (displayln "Start render data...")
  (define new-bytes* (mandelbrot2 m-width m-height))
  (printts)  
  (displayln "Start render bitmap...")
  (send m-bitmap set-argb-pixels 0 0 m-width m-height new-bytes*)
  ;(printts)
  (send viewer refresh-now)
  )

(define (zoom in e)
  (define x (send e get-x))
  (define y (send e get-y))
  ;(printf "~a, ~a, zoom ~a\n" x y in)
  (define diff (- Q1 Q2))
  (define e-pos-offset (make-rectangular
                        (* (real-part diff) (/ x (sub1 m-width)))
                        (* (imag-part diff) (/ y (sub1 m-height)))))
  (define p (- Q1 e-pos-offset))
  ;(printf "offset: ~a, p-e: ~a\n" e-pos-offset p)
  (if in
      (set! diff (/ diff 4.0))
      (set! diff (* diff 1.0)))
  (set! Q1 (+ p diff))
  (set! Q2 (- p diff))
  
  ; Adjust max iteration to get detailed image on zoom
  (if in
      (when (< maxIteration maximumIteration)
        (set! maxIteration (+ maxIteration stepIteration)))
      (when (> maxIteration minimumIteration)
        (set! maxIteration (- maxIteration stepIteration))))
  (printf "New iteration limit: ~a\n" maxIteration)
  
  (update-viewer m-viewer))

(define canvas-box%
  (class canvas%
    (define/override (on-event e)
      (define e-type (send e get-event-type))
      (cond 
        [(equal? e-type 'left-up) (zoom #t e)]
        [(equal? e-type 'right-up) (zoom #f e)])
      ; need call super on-event?
      ;(displayln e-type)
      )
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
  
  (if (and (not force)
           (equal? m-width width)
           (equal? m-height height))
      (displayln "No change")
      (set! m-bitmap (create-m-bitmap width height))
      )
  (set! m-width width)
  (set! m-height height)
  
  (update-viewer m-viewer)
  )

(update-mb m-width m-height #t)
(send frame show #t)
