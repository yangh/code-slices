#lang racket/gui

; TODO
; * Use memorization to optimize color-idx if possible,
;    ref: http://blog.racket-lang.org/2012/11/generics.html
; * How about use racket/flomap? to render image?
;
; * Drap 'n Drop to change view port
;
; * Over view when zoomed, like a mini map

(require racket/future)
(require racket/date)

(define start-ts (current-milliseconds))

(define (printts [reset #t] #:msg [args empty])
  (define ts (current-milliseconds))
  (define-values (q r) (quotient/remainder (- ts start-ts) 1000))
  (when (not (empty? args))
    (printf "Time elapsed: ~a.~as ~a\n" q r args))
  (set! start-ts ts))

(define color-idx-max 255)
;(define color-idx-max 768)

(define (gen-color [alpha #f])
  (for/list ([n color-idx-max])
    (list->bytes (if alpha
      (list 255 n n n)
      (list n n n)))
  ))

(define (gen-color2 [alpha #f])
  (define cs '())
  (define cmax color-idx-max)
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
(define m-width 326)
(define m-height 300)
(define bpp 4)
(define colors (gen-color #t))

(define std-Q1 (make-rectangular -2.25 1.5))
(define std-Q2 (make-rectangular 1 -1.5))
(define Q1 std-Q1)
(define Q2 std-Q2)

(define minimumIteration 50)
(define maximumIteration 500)
(define stepIteration 50)

; Current maximum iteration
(define maxIteration minimumIteration)

; Set as max part of Q1, Q2
(define escapeRadius 2.25)
(define m-viewer 1)
(define sub-square-max 2)
(define zoom-out-level 16.0)
(define zoom-in-level 2.0)

(define (argb-fill data argb pos)
  (define cpos (* pos bpp))
  (bytes-copy! data cpos argb))

(define debug-bytes 0)
(define (mandelbrot2 width height)
  (define m-bytes* (make-bytes (* width height bpp)))

  (define (bloop xs xe ys ye pl buffered)
    (define all-res (place-channel-get pl))
    (printts #:msg "Got idx data")
    (define line-width (- xe xs))
    (define byte-square-pos (* (+ (* width ys) xs) bpp))

    (for ([y (in-range ys ye)]
          [line-res all-res])
      ;(when buffered
        ;(place-channel-put pl "."))
      (define byte-line-pos (+ byte-square-pos (* (* width (- y ys) bpp))))
      (define line-data
        (bytes-append* #""
                      (for/list ([idx line-res])
                        (list-ref colors idx))))
      (bytes-copy! m-bytes* byte-line-pos line-data)
      )
    (printts #:msg "Finish render bytes")
    (place-wait pl)
    )
  ; many places
  (define count sub-square-max)
  (define pls
    (for*/list ([r count]
                [c count])
      (define pl (dynamic-place "mandelbrot-worker.rkt" 'place-main))
      (define y-step (/ height count))
      (define x-step (/ width count))
      (define args (list width height
                         (* r x-step) (* (add1 r) x-step)
                         (* c y-step) (* (add1 c) y-step)
                         Q1 Q2
                         escapeRadius maxIteration color-idx-max #t))
      ;(displayln args)
      (place-channel-put pl args)
      pl))

  (for* ([r count]
         [c count])
    (define y-step (/ height count))
    (define x-step (/ width count))
    (define pl (list-ref pls (+ (* r 2) c)))
    (bloop (* r x-step) (* (add1 r) x-step)
           (* c y-step) (* (add1 c) y-step) pl #t))
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
  (printts #:msg "Done")
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
      (set! diff (* diff zoom-in-level))
      (set! diff (/ diff zoom-out-level)))
  (set! Q1 (+ p diff))
  (set! Q2 (- p diff))

  ; Adjust max iteration to get detailed image on zoom
  (if in
      (when (> maxIteration minimumIteration)
        (set! maxIteration (- maxIteration stepIteration)))
      (when (< maxIteration maximumIteration)
        (set! maxIteration (+ maxIteration stepIteration)))
)
  (printf "New iteration limit: ~a\n" maxIteration)

  (update-viewer m-viewer))

(define canvas-box%
  (class canvas%
    (define/override (on-event e)
      (define e-type (send e get-event-type))
      (cond
        [(equal? e-type 'left-up)  (zoom #f e)]
        [(equal? e-type 'right-up) (zoom #t e)])
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
