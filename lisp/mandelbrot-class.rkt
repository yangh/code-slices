#lang racket

(require racket/gui)
(require racket/draw)
(require images/flomap)

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
     [maxIteration 25]
     [width 326]
     [height 300])
    
    (define m-Q1 Q1)
    (define m-Q2 Q2)
    (define m-viewport-changed #t) ; init in true first draw
    (define m-viewsize-changed #f)
    (define points-info-hash (make-hash))
    
    (define minimumIteration 25)
    (define maximumIteration 500)
    (define stepIteration 25)
    
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
      (values m-Q1 m-Q2))
    (define/public (set-viewport q1 q2)
      (when (or
             (not (equal? m-Q1 q1))
             (not (equal? m-Q2 q2)))
        (set! m-Q1 q1)
        (set! m-Q2 q2)
        (set! m-viewport-changed #t)))

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
        (set m-viewport-changed #f)
        (set m-viewsize-changed #f)
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
        (for ([y (in-range ys ye)]
              [line-res all-res])
          ;(when buffered
          ;(place-channel-put pl "."))
          ;(display mark)
          (flush-output)
          
          (define byte-line-pos (* (* width y) bpp))
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
      (define count 4)
      (define pls
        (for/list ([i count])
          (define pl (dynamic-place "mandelbrot-worker.rkt" 'place-main))
          (define y-step (/ height count))
          (define args (list width height
                             0 width (* i y-step) (* (add1 i) y-step)
                             Q1 Q2
                             escapeRadius maxIteration
                             color-idx-max #t))
          (place-channel-put pl args)
          pl))
      
      ; start loops to receive result from places
      (for ([i count]
            [pl pls])
        (define y-step (/ height count))
        (bloop 0 width (* i y-step) (* (add1 i) y-step) pl #t))
      m-bytes*)
  ))


; UI
(define m-width 326)
(define m-height 300)

(define frame (new frame% [label "Mandelbrot"]
                   [width 300]
                   [height 200]
                   [border 0]
                   [alignment '(center center)]))

(define m-viewer 1)
(define m-bitmap 1)

(define (draw-mandelbrot dc)
  ;(displayln "TODO: draw to canvas")
  (send dc draw-bitmap m-bitmap 0 0)
  )

(define (update-viewer viewer mb)
  ;(displayln "TODO: update bitmap")
  (set! m-bitmap (send mb get-bitmap))
  ;(printts)
  (send viewer refresh-now)
  )

(define (zoom in e)
  (define x (send e get-x))
  (define y (send e get-y))
  (printf "~a, ~a, zoom ~a\n" x y in)
)

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
      (printf "New size ~a, ~a\n" w h)
      )
    (super-new)))

(set! m-viewer (new canvas-box% 
                    [parent frame]
                    [min-width m-width]
                    [min-height m-height]
                    [paint-callback
                     (lambda (canvas dc)
                      (draw-mandelbrot dc))]
                    ))

(define m (new mandelbrot%
               [maxIteration 25]
               [width m-width]
               [height m-height]))


(update-viewer m-viewer m)
(send frame show #t)

