#lang racket
(provide place-main)
 
(define (place-main2 pch)
  (place-channel-put pch (format "Hello from place ~a"
                                  (place-channel-get pch))))

(define (place-main pch)
  (let* ([args (place-channel-get pch)]
         [width  (list-ref args 0)]
         [height (list-ref args 1)]
         [max    (list-ref args 2)])
    (for* ([w width]
           [h height]
           [i width])
      (* (* (* w h) w) h))
    (place-channel-put pch (format "Hello from place ~a,~a"
                                   width height)))
  )
