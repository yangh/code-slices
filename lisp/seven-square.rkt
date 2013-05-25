#lang racket/gui

(require "adb.rkt")

(define fb-capture-timer 1)

(define sq-frame%
  (class frame%
    (super-new)
    (define (on-close)
      (printf "Exit..\n")
      (send fb-capture-timer stop))
    (augment on-close)))

(define frame (new sq-frame% [label "Seven Square"]))

(define WIDTH 480)
(define HEIGHT 800)
(define BPP 4)

(define fbbitmap (make-object bitmap% WIDTH HEIGHT #f #t))

(define (draw-rawimage dc)
  ;(send fbbitmap set-argb-pixels 0 0 WIDTH HEIGHT (load1frame))
  (send dc draw-bitmap fbbitmap 0 0))

(define viewer (new canvas% [parent frame]
                    [min-width WIDTH]
                    [min-height HEIGHT]
                    [paint-callback
                     (lambda (canvas dc)
                       (draw-rawimage dc))]))

(define (showf) (send frame show #t))

(define adb (new adb%))

(struct fbinfo (version
                bpp
                size
                width
                height
                red_offset
                red_length
                blue_offset
                blue_length
                green_offset
                green_length
                alpha_offset
                alpha_length)
                #:transparent)

(define (le32->number bin)
  (+ (bytes-ref bin 0)
     (arithmetic-shift (bytes-ref bin 1) 8)
     (arithmetic-shift (bytes-ref bin 2) 16)
     (arithmetic-shift (bytes-ref bin 3) 24)))

(define (read-fbinfo in)
  (define-values (a b c d e f g h i j k l m)
    (apply values (for/list ([i 13])
                    (le32->number (read-bytes 4 in)))))
  (fbinfo a b c d e f g h i j k l m))

(define fb-callback
  (lambda (in out)
    (define fb (read-fbinfo in))
    ;(printf "~a\n" fb)
    (define raw-size (fbinfo-size fb))
    (define raw (read-bytes raw-size in))
    (cond
      [(equal? raw-size (bytes-length raw))
       (send fbbitmap set-argb-pixels 0 0 WIDTH HEIGHT
             ; Fake rgba to argbraw
             (bytes-append (make-bytes 1 255) raw))
       (send viewer refresh-now)]
      [else (displayln "Dropped currupted frame")])
    ))

(define fb-capture
  (lambda ()
    (send adb local-service 'framebuffer "" #:cb fb-callback)))

(set! fb-capture-timer (new timer% [notify-callback fb-capture]))
(send fb-capture-timer start 50)
(showf)
