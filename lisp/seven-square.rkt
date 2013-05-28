#lang racket/gui

(require "adb.rkt")
(require images/flomap)

(define fb-capture-timer 1)
(define do-scale #f)

(define sq-frame%
  (class frame%
    (super-new)
    (define (on-close)
      (printf "Exit..\n")
      (send fb-capture-timer stop))
    (augment on-close)))

(define frame (new sq-frame% [label "Seven Square"]))

(define WIDTH 360)
(define HEIGHT 600)
(define BPP 4)

(define viewer (new canvas% [parent frame]
                    [min-width WIDTH]
                    [min-height HEIGHT]))

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

(define fbbitmap (make-object bitmap%
                   1 1 #f #t))

(define (update-bitmap-size w h)
  (when (or (not (equal? w (send fbbitmap get-width)))
            (not (equal? h (send fbbitmap get-height))))
    (set! fbbitmap (make-object bitmap%
                     w h #f #t))
  (when (not do-scale)
    (displayln "Resize window")
    (send frame resize w h))
    ))

(define fb-callback
  (lambda (in out)
    (define fb (read-fbinfo in))
    ;(printf "~a\n" fb)
    (define-values (size width height)
      (values (fbinfo-size fb)
              (fbinfo-width fb)
              (fbinfo-height fb)))
    (define raw (read-bytes size in))

    (define (draw raw)
      (update-bitmap-size width height)
      (send fbbitmap set-argb-pixels 0 0 width height
            ; Fake rgba to argbraw
            (bytes-append (make-bytes 1 255) raw))
      (cond
        [do-scale
         (define floimg (bitmap->flomap fbbitmap))
         (define scaled (flomap->bitmap
                         (flomap-scale floimg
                                       (/ WIDTH width)
                                       (/ HEIGHT height))))
         (send (send viewer get-dc)
               draw-bitmap scaled 0 0)]
        [else
         (send (send viewer get-dc)
               draw-bitmap fbbitmap 0 0)]))
    (cond
      [(equal? size (bytes-length raw)) (draw raw)]
      [else (displayln "Dropped currupted frame")])
    ))

(define fb-capture
  (lambda ()
    (send adb local-service 'framebuffer "" #:cb fb-callback)))

(set! fb-capture-timer (new timer% [notify-callback fb-capture]))
(send fb-capture-timer start 50)
(showf)
