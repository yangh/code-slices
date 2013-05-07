#lang racket/gui

; TODO
; 1. Use memorization to optimize color-idx if possible,
;    ref: http://blog.racket-lang.org/2012/11/generics.html
; 2. Use place to cacul mandelbrot set and runtime thread
;    to find color index and render image
; 3. How about use racket/flomap? to render image?
;
; 4. Drap 'n Drop to change view port
;
; 5. Over view when zoomed, like a mini map

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
          (list->bytes (list 255 r g b))
          (list->bytes (list r g b))))))

; Keep ratio with (- Q1 Q2)
(define m-width 750)
(define m-height 600)
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

(define (color-idx c z i)
  (define mu ( - i (/ (log (log (magnitude (+ (* z z) c)))) logEscapeRadius)))
  (define idx (* (/ mu maxIteration) 768))
  (if (or (>= idx 768) (< idx 0))
      0
      (inexact->exact (round idx))))

(define (argb-fill data argb pos)
  (define cpos (* pos bpp))
  (bytes-copy! data cpos argb))

(require racket/future)

(define (iterations c z i)
  (if (or (>= i maxIteration) (>= (magnitude z) escapeRadius))
      (values i z)
      (iterations c (+ (* z z) c) (add1 i))))

(define debug-bytes 0)
(define (mandelbrot2 width height)
  (define m-bytes* (make-bytes (* width height bpp)))
  (define x-step (make-rectangular (/ (abs (real-part (- Q1 Q2))) (sub1 width)) 0))
  (define y-step (make-rectangular 0 (/ (abs (imag-part (- Q1 Q2))) (sub1 height))))


  ;(printf "step (~a, ~a)\n" x-step y-step)
  (define (bloop xs xe ys ye)
    (for ([ y (in-range ys ye)])
      (define y-inc (- Q1 (* y-step y)))
      (define line-pos (* width y))
      (define byte-line-pos (* line-pos bpp))

      (for ([x (in-range xs xe)])
        (define z (+ y-inc (* x-step x)))
        (define-values (iter Z) (iterations z z 0))

        (define idx 0)
        (when (< iter maxIteration)
          (set! idx (color-idx z Z iter)))
        (define cpos (+ byte-line-pos (* bpp x)))
        (bytes-copy! m-bytes* cpos (list-ref colors idx))
        ;(argb-fill m-bytes* (list-ref colors idx) (+ line-pos x))
        ;(cacul-n-fill z Z iter (+ line-pos x))
      )))
  ;two thread
  (let ([f (future (lambda () (bloop 0 width 0 (/ height 2))))])
    (list (bloop 0 width (/ height 2) height) (touch f)))
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
  (printf "Start render data...~ax~a\n" m-width m-height)
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
      (set! diff (/ diff 8.0))
      (set! diff (* diff 2.0)))
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
    (define/override (on-size w h)
      ;(super on-size w h)
      (when (not (and (equal? w m-width) (equal? h m-height)))
        ;(set! m-width w)
        ;(set! m-height h)
        (printf "New size ~a, ~a\n" w h)
        )
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
  (when (or force
            (not (equal? m-width width))
            (not (equal? m-height height)))
    (set! m-width width)
    (set! m-height height)
    (set! m-bitmap (create-m-bitmap width height))
    (update-viewer m-viewer)
    (send frame resize width height)
  ))

(update-mb m-width m-height #t)
(send frame show #t)