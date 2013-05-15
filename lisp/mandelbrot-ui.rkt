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
(define viewer-main-width 500)
(define viewer-main-height 446)

(define mini2-viewer 1)

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

  (define update-marker
    (lambda (canvas event)
      (define e-type (send event get-event-type))
      (cond
        [(equal? e-type 'left-up)
           (displayln "Update markder...")
           (send canvas update-view)])
      (send mini2-viewer restore-mb-viewport)
      (zoom-mb mini2-viewer event)
    ))

(define mini1-viewer (new canvas-box%
                         [parent (new panel% [parent left-v-pane]
                                             [style '(border)])]
                         [min-width viewer-mini-width]
                         [min-height viewer-mini-height]
                         [draw-marker draw-cross-marker]
                         [event-callback update-marker]
                    ))
(new message%	 
   	 	[label "[Overview Level 2]"]	 
   	 	[parent (new vertical-pane%
                             [parent left-v-pane]
                             [alignment '(left center)])])

(set! mini2-viewer (new canvas-box%
                         [parent (new panel% [parent left-v-pane]
                                             [style '(border)])]
                         [min-width viewer-mini-width]
                         [min-height viewer-mini-height]
                    ))

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
                    ))


(send frame show #t)

;(send frame set-cursor (make-object cursor% 'watch))
;(send frame set-cursor (make-object cursor% 'arrow))
