#lang racket/gui

(define frame (new frame% [label "RawImage Viewer"]))

(define msg (new message% [parent frame]
                          [label "No events so far..."]))

(new button% [parent frame]
             [label "Click Me"]
             (callback (lambda (button event)
                         (send msg set-label "Button click"))))

(define WIDTH 480)
(define HEIGHT 800)
(define BPP 4)

(define fbbitmap (make-object bitmap% WIDTH HEIGHT #f #t))

(define (load1frame)
  (call-with-input-file "/tmp/raw.fb0"
    (lambda (in)
      ; Required argb, but data is rgba, mockup it
      (bytes-append (make-bytes 1 255) (read-bytes (* WIDTH HEIGHT BPP) in)))))

(define (draw-rawimage dc)
  (send fbbitmap set-argb-pixels 0 0 WIDTH HEIGHT (load1frame))
  (send dc draw-bitmap fbbitmap 0 0))
        
(define viewer (new canvas% [parent frame]
                    [min-width WIDTH]
                    [min-height HEIGHT]
                    [paint-callback
                     (lambda (canvas dc)
                       (draw-rawimage dc))]))

(define (showf) (send frame show #t))

(showf)
