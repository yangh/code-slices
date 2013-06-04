#lang racket/gui

(require "adb.rkt")
(require images/flomap)
(require slideshow/pict)
(require openssl/sha1)

(define fb-capture-timer 1)
(define do-scale-flomap #f)
(define do-scale-pict #t)
(define do-scale (or do-scale-flomap do-scale-pict))
(define do-fb-checksum-crc16 #f)
(define do-fb-checksum-sha1 #t)

(define sq-frame%
  (class frame%
    (super-new)
    (define (on-close)
      (printf "Exit..\n")
      (send fb-capture-timer stop))
    (augment on-close)))

(define xframe (new sq-frame% [label "Seven Square"]))

(define WIDTH 360)
(define HEIGHT 600)
(define BPP 4)

(define viewer (new canvas% [parent xframe]
                    [min-width WIDTH]
                    [min-height HEIGHT]))

(define (showf) (send xframe show #t))
(define (resize-frame w h) (send xframe resize w h))

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

(define fbbitmap (make-object bitmap% 1 1 #f #t))
(define fbhash 1024)

(define (update-bitmap-size w h)
  (unless (and (equal? w (send fbbitmap get-width))
               (equal? h (send fbbitmap get-height)))
    (set! fbbitmap (make-object bitmap% w h #f #t))
    ; FIXME: windows not scaled as excepted
    (when do-scale
      (displayln "Resize window")
      (resize-frame w h)
      (set! fbhash "reset"))
    ))

(define crctbl (list
                #x0000 #x1081 #x2102 #x3183
                #x4204 #x5285 #x6306 #x7387
                #x8408 #x9489 #xa50a #xb58b
                #xc60c #xd68d #xe70e #xf78f))

(define (crc16 data len)
  (define (cacl crc c)
    (bitwise-xor
     (bitwise-and (arithmetic-shift crc -4) #xffff)
     (list-ref crctbl (bitwise-and (bitwise-xor crc c) 15))))
  (let loop ([i 0] [crc #xffff])
    (cond
      [(= i len)
       (bitwise-and (bitwise-not crc) #xffff)]
      [else
       (loop (add1 i) (cacl crc (bytes-ref data i)))])))

(define (content-changed? raw size)
  (define newhash
    (cond
      [do-fb-checksum-crc16 (crc16 raw size)]
      [do-fb-checksum-sha1
       (define in (open-input-bytes raw))
       (define hash (sha1 in))
       (close-input-port in)
       hash]
      [else fbhash]))
  (define changed (not (equal? fbhash newhash)))
  (when changed
    ;(displayln newhash)
    (set! fbhash newhash))
  changed)

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
            ; Fake rgba to argbraw, potential perf issue?
            (bytes-append (make-bytes 1 255) raw))
      (send (send viewer get-dc) draw-bitmap
            (cond
              [do-scale-flomap
               (flomap->bitmap
                (flomap-scale (bitmap->flomap fbbitmap)
                              (/ WIDTH width)
                              (/ HEIGHT height)))]
              [do-scale-pict
               (pict->bitmap
                (scale (bitmap fbbitmap)
                       (/ WIDTH width)))]
              [else fbbitmap])
            0 0))
    (cond
      [(equal? size (bytes-length raw))
       (when (content-changed? raw size)
         (draw raw))]
      [else (displayln "Dropped currupted frame")])
    ))

(define fb-capture
  (lambda ()
    (send adb local-service 'framebuffer "" #:cb fb-callback)))

(set! fb-capture-timer (new timer% [notify-callback fb-capture]))
(send fb-capture-timer start 50)
(showf)
