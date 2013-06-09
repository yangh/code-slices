#lang racket

(provide mandelbrot%)
(provide canvas-box%)

(require racket/gui)
(require racket/draw)

(struct point (x y) #:transparent)

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

(define mandelbrot%
  (class object%
    (init-field
     [Q1 (make-rectangular -2.25 1.5)]
     [Q2 (make-rectangular 1 -1.5)]
     [maxIteration 50]
     [width 326]
     [height 300]
     [sub-square-max 2]
     [zoom-out-level 8.0]
     [zoom-in-level 2.0])
    
    (define std-Q1 Q1)
    (define std-Q2 Q2)
    (define m-viewport-changed #t) ; init in true first draw
    (define m-viewsize-changed #f)
    (define points-info-hash (make-hash))
    
    (define minimumIteration 50)
    (define maximumIteration 1000)
    (define stepIteration 80)
    
    ; Set as max part of Q1, Q2
    (define escapeRadius 2.25)
    (define logEscapeRadius (log escapeRadius))
    
    (super-new)

    (define/public (get-point-info p)
      (if (hash-has-key? points-info-hash p)
          (hash-ref points-info-hash p)
          #f))

    ; Viewport
    (define/public (get-viewport)
      (values Q1 Q2))
    (define/public (set-viewport q1 q2)
      (when (or
             (not (equal? Q1 q1))
             (not (equal? Q2 q2)))
        (printf "New viewport: ~a ~a\n" q1 q2)
        (set! Q1 q1)
        (set! Q2 q2)
        (set! m-viewport-changed #t)))
    (define/public (set-std-viewport)
      (set-viewport std-Q1 std-Q2))

    (define/public (zoom in x y)
      (define diff (- Q1 Q2))
      (define e-pos-offset (make-rectangular
                            (* (real-part diff) (/ x (sub1 width)))
                            (* (imag-part diff) (/ y (sub1 height)))))
      (define p (- Q1 e-pos-offset))
      ;(printf "offset: ~a, p-e: ~a\n" e-pos-offset p)
      (if in
        (set! diff (* diff zoom-in-level))
        (set! diff (/ diff zoom-out-level)))
      (set-viewport (+ p diff) (- p diff))

      ; Adjust max iteration to get detailed image on zoom
      (if in
          (when (> maxIteration minimumIteration)
            (set! maxIteration (- maxIteration stepIteration)))
          (when (< maxIteration maximumIteration)
            (set! maxIteration (+ maxIteration stepIteration))))
      (printf "New iteration limit: ~a\n" maxIteration))

    ; Iterations
    (define/public (get-max-iter)
      maxIteration)
    (define/public (set-max-iter iter)
      (set! maxIteration iter))
    
    ; Re-caculate
    (define/public (refresh)
      (define changed #f)
      (when (or m-viewport-changed
                m-viewsize-changed)
        (displayln "TODO: re-caculate")
        (set! m-viewport-changed #f)
        (set! m-viewsize-changed #f)
        (set! changed #t))
      changed)
    
    ; Bitmap
    (define bpp 4)
    (define colors (gen-color #t))
    (define (create-bitmap w h)
      (make-object bitmap%  w h #f #t))

    (define m-bitmap (create-bitmap width height))

    (define/public (set-viewsize w h)
      (when (or
             (not (equal? width w))
             (not (equal? height h)))
        (printf "New viewsize: ~a ~a\n" w h)
        (set! width w)
        (set! height h)
        (set! m-viewsize-changed #t)
        (set! m-bitmap (create-bitmap width height))
      ))

    (define/public (get-bitmap)
      (when (refresh)
        (displayln "Update bitmap with new bytes..")
        (send m-bitmap set-argb-pixels
              0 0 width height
              (get-bytes)))
      m-bitmap)
    
    (define/public (get-bytes)
      (define m-bytes* (make-bytes (* width height bpp)))

      ; loop to process data from place
      (define (bloop xs xe ys ye pl buffered)
        (define all-res (place-channel-get pl))
        (printts #:msg "Got idx data")
        (define mark (if (> ys 0) "=" "-"))
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
      
      ; create many places
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
  ))


(define canvas-box%
  (class canvas%
    (init-field [event-callback
                 (lambda (canvas event) #t)]
                [draw-marker
                 (lambda (canvas pos-list) (displayln "Draw marker nothing."))]
                [m-mandelbrot (new mandelbrot%)])
    (super-new)

    ; Single pair for click, Double for a area
    (define last-event-pos '())
    (define/public (get-last-event-pos) last-event-pos)

    (define m-width (send this get-width))
    (define m-height (send this get-height))
    ;(printf "Canvas size: ~a ~a\n" m-width m-height)

    (define zoom-target-canvas 1)
    (define/public (set-zoom-target t)
        (set! zoom-target-canvas t))
    (define/public (get-zoom-target)
      zoom-target-canvas)

    (define/public (get-mb) m-mandelbrot)
    
    (define m-bitmap (make-object bitmap% m-width m-height #f #t))

    (define/public (transfer-viewport-to-target)
      (define-values (q1 q2) (send m-mandelbrot get-viewport))
      (define max-iter (send m-mandelbrot get-max-iter))
      (define target-mb (send zoom-target-canvas get-mb))
      (send target-mb set-viewport q1 q2)
      (send target-mb set-max-iter max-iter))

    (define/public (update-view)
      (define new-bitmap (send m-mandelbrot get-bitmap))
      (when (not (equal? m-bitmap new-bitmap))
        (set! m-bitmap new-bitmap))
      (on-paint))
    
    (define/public (zoom in x y)
      (printf "~a, ~a, zoom ~a\n" x y in)
      (send m-mandelbrot zoom in x y)
      (update-view))

    (define/override (on-event e)
      ; Need call super on-event?
      ;(displayln e-type)
      (define x (send e get-x))
      (define y (send e get-y))
      (define e-type (send e get-event-type))
      (cond
        [(equal? e-type 'left-down)
           (set! last-event-pos (list (list x y)))]
        [(equal? e-type 'left-up)
           (set! last-event-pos (list (car last-event-pos) (list x y)))])
      (event-callback this e)
      )
    (define/override (on-size w h)
      ;(super on-size w h)
      (send m-mandelbrot set-viewsize w h)
      (update-view)
      (printf "New size ~a, ~a\n" w h)
      )
    (define/override (on-paint)
      ;(super on-paint)
      ;(printf "on-paint\n")
      (define dc (send this get-dc))
      (send dc draw-bitmap m-bitmap 0 0)
      (draw-marker this last-event-pos)
      )
  ))

; UI
(module+ main
  (define frame (new frame% [label "Mandelbrot"]
                   [width 300]
                   [height 200]
                   [border 0]
                   [alignment '(center center)]))

  (define zoom-mb
    (lambda (canvas event)
            (define x (send event get-x))
            (define y (send event get-y))
            (define e-type (send event get-event-type))
            (cond
              [(equal? e-type 'left-up)  (send canvas zoom #f x y)]
              [(equal? e-type 'right-up) (send canvas zoom #t x y)])))

  (define m-viewer (new canvas-box% 
                      [parent frame]
                      [min-width 330]
                      [min-height 300]
                      [event-callback zoom-mb]
                      ))

  (send frame show #t)
)
