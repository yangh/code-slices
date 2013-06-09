#lang racket/gui

(require "adb.rkt")
(require slideshow/pict)
(require openssl/sha1)

(define fb-capture-timer 1)
(define do-scale-flomap #f)
(define do-scale-pict #t)
(define do-scale (or do-scale-flomap do-scale-pict))

(define do-fb-checksum-sha1 #t)
(define wait-thread-id #f)

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
  (apply fbinfo (for/list ([i 13])
                  (define val (read-bytes 4 in))
                  (cond
                    [(bytes? val) (le32->number val)]
                    [else 0]))))

(define sq-frame%
  (class frame%
    (super-new)

    (send this resize WIDTH HEIGHT)

    (define/augment (on-close)
      (printf "Exit..\n")
      (when (thread? wait-thread-id)
        (kill-thread wait-thread-id))
      (send fb-capture-timer stop))

    (define/override (on-subwindow-char win k)
      (define key (send k get-key-release-code))
      ;(displayln key)
      (cond
        [(equal? key 'f12) (switch-screen-oreintation)]
        ;[(equal? key 'q) (send this on-close)]
        ))
    ))


(define WIDTH 360)
(define HEIGHT 600)

(define xframe (new sq-frame% [label "Seven Square"]))

(define (showf) (send xframe show #t))
(define (resize-frame w h) (send xframe resize w h))

(define fbbitmap (make-object bitmap% 1 1 #f #t))
(define fbhash 1024)
(define landscape (/ pi 2))
(define portrait (* pi 2))
(define fbtheta portrait)

(define draw-fb
  (lambda (canvas dc)
    (send dc draw-bitmap
          (cond
            [do-scale-pict
             (pict->bitmap
              (rotate
               (scale (bitmap fbbitmap)
                      (/ WIDTH (send fbbitmap get-width)))
               fbtheta))]
            [else fbbitmap])
          0 0)))

(define viewer (new canvas% [parent xframe]
                    ;[min-width WIDTH]
                    ;[min-height HEIGHT]
                    [paint-callback draw-fb]))

(define switch-screen-oreintation
  (lambda ()
    ; TODO: user width of frame
    (define w (send xframe get-width))
    (define h (send xframe get-height))
    ;(printf "Rotate window: ~a,~a\n" w h)
    (cond
      [(equal? fbtheta landscape)
       (set! fbtheta portrait)
       (resize-frame h w)]
      [(equal? fbtheta portrait)
       (set! fbtheta landscape)
       (resize-frame h w)])
    (send viewer refresh)
    ))

(define (update-bitmap-size w h)
  (unless (and (equal? w (send fbbitmap get-width))
               (equal? h (send fbbitmap get-height)))
    (set! fbbitmap (make-object bitmap% w h #f #t))
    ; FIXME: windows not scaled as excepted
    (when do-scale
      (displayln "Resize window")
      ;(resize-frame w h)
      (set! fbhash "reset"))
    ))

(define (content-changed? raw size)
  (define newhash
    (cond
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
    (define (draw raw)
      (update-bitmap-size width height)
      (send fbbitmap set-argb-pixels 0 0 width height
            ; Fake rgba to argbraw, potential perf issue?
            (bytes-append (make-bytes 1 255) raw))
      (send viewer refresh))

    (define fb (read-fbinfo in))
    ;(printf "~a\n" fb)
    (define-values (size width height)
      (values (fbinfo-size fb)
              (fbinfo-width fb)
              (fbinfo-height fb)))
    (define raw (read-bytes size in))

    (cond
      [(and (> width 0)
            (> height 0)
            (equal? size (bytes-length raw)))
       (when (content-changed? raw size)
         (draw raw))]
      [else
       (printf "Dropped currupted frame: ~a/~a\n"
               (bytes-length raw) size)])
    ))


(define adb (new adb%))
(define fb-interval 50)

(define (start-wait-thread)
  (set! wait-thread-id
        (thread
         (lambda ()
           (send adb wait-for-device)
           (set! wait-thread-id #f)
           (send fb-capture-timer start fb-interval)))))

(define fb-capture
  (lambda ()
    (unless (send adb local-service
                  'framebuffer "" #:cb fb-callback)
      (unless (thread? wait-thread-id)
        (send fb-capture-timer stop)
        (start-wait-thread))
      )))

(set! fb-capture-timer (new timer% [notify-callback fb-capture]))
(send adb wait-for-device)
(send fb-capture-timer start fb-interval)
(showf)
