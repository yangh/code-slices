#lang racket/gui

(define (zoom in e)
  (define x (send e get-x))
  (define y (send e get-y))
  (printf "TODO: ~a, ~a, zoom ~a\n" x y in)
  )

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
    (super-new)))

(define window-width 246)
(define window-height 210)
(define viewer-mini-width 240)
(define viewer-mini-height 160)
(define viewer-main-width 492)
(define viewer-main-height 420)

(define frame (new frame% [label "Mandelbrot"]
                   [width window-width]
                   [height window-height]
                   [border 0]
                   [alignment '(center center)]))

(define mv-pane (new vertical-pane%
                    [parent frame]
                    [border 6]))

(define h-pane (new horizontal-pane%
                    [parent mv-pane]
                    [spacing 6]))

(define left-v-pane (new vertical-pane%
                         [parent h-pane]
                         [alignment '(left top)]))
(define right-v-pane (new vertical-pane%
                         [parent h-pane]
                         [alignment '(left top)]))

(new message%	 
   	 	[label "[Overview]"]	 
   	 	[parent (new vertical-pane%
                             [parent left-v-pane]
                             [alignment '(left center)])])

(define mini1-viewer (new canvas-box% [parent 
                                       (new panel%
                                            [parent left-v-pane]
                                            [style '(border)])]
                    [min-width viewer-mini-width]
                    [min-height viewer-mini-height]
                    [paint-callback
                     (lambda (canvas dc)
                      (displayln "TODO: draw mini1"))]
                    ))
(new message%	 
   	 	[label "[Overview Level 2]"]	 
   	 	[parent (new vertical-pane%
                             [parent left-v-pane]
                             [alignment '(left center)])])

(define mini2-viewer (new canvas-box% [parent
                                       (new panel%
                                            [parent left-v-pane]
                                            [style '(border)])]
                    [min-width viewer-mini-width]
                    [min-height viewer-mini-height]
                    [paint-callback
                     (lambda (canvas dc)
                      (displayln "TODO: draw mini2"))]
                    ))

(define mini-z-pos (new message%	 
                        [label "[Pos: a+bi]"]	 
                        [parent (new vertical-pane%
                                     [parent left-v-pane]
                                     [alignment '(left center)])]))

(define mini-z-iter (new message%	 
                        [label "[Iteration: 255]"]	 
                        [parent (new vertical-pane%
                                     [parent left-v-pane]
                                     [alignment '(left center)])]))

(define mini-z-xxx (new message%	 
                        [label "[TODO: 255]"]	 
                        [parent (new vertical-pane%
                                     [parent left-v-pane]
                                     [alignment '(left center)])]))

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
                    [paint-callback
                     (lambda (canvas dc)
                      (displayln "TODO: draw mini2"))]
                    ))


(send frame show #t)

(send frame set-cursor (make-object cursor% 'watch))
;(send frame set-cursor (make-object cursor% 'arrow))
