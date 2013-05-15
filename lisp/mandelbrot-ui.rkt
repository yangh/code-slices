#lang racket/gui

(define (zoom in e)
  (define x (send e get-x))
  (define y (send e get-y))
  (printf "TODO: ~a, ~a, zoom ~a\n" x y in)
  )

(require "mandelbrot-class.rkt")

(define window-width 246)
(define window-height 210)
(define viewer-mini-width 240)
(define viewer-mini-height 210)
(define viewer-main-width 510)
(define viewer-main-height 450)

(define frame (new frame% [label "Mandelbrot"]
                   [width window-width]
                   [height window-height]
                   [border 0]
                   [alignment '(center center)]))

(define mv-pane (new vertical-pane% [parent frame] [border 6]))
(define mh-pane (new horizontal-pane% [parent mv-pane] [spacing 6]))

(define left-v-pane (new vertical-pane%
                         [parent mh-pane]
                         [alignment '(left top)]))
(define right-v-pane (new vertical-pane%
                         [parent mh-pane]
                         [alignment '(left top)]))

(new message% [label "[Overview]"]
              [parent (new vertical-pane%
                           [parent left-v-pane]
                           [alignment '(left center)])])

(define (transform-point canvas1 canvas2 x y)
  (define w1 (send canvas1 get-width))
  (define w2 (send canvas2 get-width))
  (define h1 (send canvas1 get-height))
  (define h2 (send canvas2 get-height))
  (values (round(* x (/ w2 w1)))
          (round(* y (/ h2 h1)))))

(define zoom-mb
  (lambda (canvas event)
    (define x (send event get-x))
    (define y (send event get-y))
    (define e-type (send event get-event-type))
    (cond
      [(equal? e-type 'left-up)  (send canvas zoom #f x y)]
      [(equal? e-type 'right-up) (send canvas zoom #t x y)])))

(define draw-cross-marker
  (lambda (canvas pos-list)
    (displayln "Draw my cross marker")
    (when (not (empty? pos-list))
      (define pos (cdr pos-list))
      (when (not (empty? pos))
        (define-values (x y) (apply values (list-ref pos 0)))
        (printf "Draw cross at: ~a ~a\n" x y)
        (define dc (send canvas get-dc))
        (define c-radius 5)
        (send dc set-pen "white" 1 'solid)
        (send dc draw-line x (- y c-radius) x (+ y c-radius))
        (send dc draw-line (- x c-radius) y  (+ x c-radius) y)
        )
      (displayln pos-list))))

(define zoom-to-target
  (lambda (canvas event)
    (define e-type (send event get-event-type))
    (cond
      [(equal? e-type 'left-up)
       (displayln "Update markder...")
       (send canvas update-view)
       (send canvas transfer-viewport-to-target)
       
       (define x (send event get-x))
       (define y (send event get-y))
       (define target (send canvas get-zoom-target))
       (define-values (nx ny) (transform-point canvas target x y))
       (send event set-x nx)
       (send event set-y ny)
       (printf "Transformed event: ~a ~a -> ~a ~a\n" x y nx ny)
       (zoom-mb target event)])
    ))

(define mini1-viewer (new canvas-box%
                         [parent (new panel% [parent left-v-pane]
                                             [style '(border)])]
                         [min-width viewer-mini-width]
                         [min-height viewer-mini-height]
                         [draw-marker draw-cross-marker]
                         [event-callback zoom-to-target]
                    ))
(new message%
     [label "[Overview Level 2]"]	 
     [parent (new vertical-pane%
                  [parent left-v-pane]
                  [alignment '(left center)])])

(define mini2-viewer (new canvas-box%
                          [parent (new panel% [parent left-v-pane]
                                       [style '(border)])]
                          [min-width viewer-mini-width]
                          [min-height viewer-mini-height]
                          [m-mandelbrot (new mandelbrot% [zoom-out-level 16.0])]
                          [draw-marker draw-cross-marker]
                          [event-callback zoom-to-target]
                    ))

(send mini1-viewer set-zoom-target mini2-viewer)

(define mini-z-pos (new message%	 
                        [label "[Pos: a+bi]"]	 
                        [parent (new vertical-pane%
                                     [parent mv-pane]
                                     [alignment '(right center)])]))

(define mini-z-iter (new message%	 
                        [label "[Iteration: 255]"]	 
                        [parent (new vertical-pane%
                                     [parent mv-pane]
                                     [alignment '(right center)])]))

(define mini-z-xxx (new message%	 
                        [label "[TODO: 255]"]	 
                        [parent (new vertical-pane%
                                     [parent mv-pane]
                                     [alignment '(right center)])]))

; Main view
(define msg-main-z-pos (new message%	 
                            [label "[Ratio: a+bi]"]	 
                            [parent (new vertical-pane%
                                         [parent right-v-pane]
                                         [alignment '(right center)])]))
(define main-viewer (new canvas-box% [parent (new panel%
                                                  [parent right-v-pane]
                                                  [style '(border)])]
                         [min-width viewer-main-width]
                         [min-height viewer-main-height]
                         [event-callback zoom-mb]
                         ))

(send mini2-viewer set-zoom-target main-viewer)

(send frame show #t)

;(send frame set-cursor (make-object cursor% 'watch))
;(send frame set-cursor (make-object cursor% 'arrow))
