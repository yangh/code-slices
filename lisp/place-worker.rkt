#lang racket
(provide place-main)
 
(define (place-main pch)
  (place-channel-put pch (format "Hello from place ~a"
                                  (place-channel-get pch))))
