#lang racket

(provide place-main)

(define debug-trace #f)
(define (place-main pch)
  (define args (place-channel-get pch))
  (define-values (width
                  height
                  xs xe ys ye
                  Q1 Q2
                  escapeRadius
                  maxIteration
                  buffered) (apply values args))
  (define x-step (make-rectangular (/ (abs (real-part (- Q1 Q2))) (sub1 width)) 0))
  (define y-step (make-rectangular 0 (/ (abs (imag-part (- Q1 Q2))) (sub1 height))))
  (define logEscapeRadius (log escapeRadius))
  (define mark (make-bytes 1 (+ 97 (/ ys (- ye ys)))))

  (define (color-idx c z i)
    (define mu ( - i (/ (log (log (magnitude (+ (* z z) c)))) logEscapeRadius)))
    ; shit
    (define idx (inexact->exact (round (real-part (* (/ mu maxIteration) 768)))))
    (if (or (>= idx 768) (< idx 0))
        0
        idx))

  (define lls
    (for/list ([y (in-range ys ye)])
      (define y-inc (- Q1 (* y-step y)))
      ; trace
      (when debug-trace
        (display mark)
        (flush-output))
      (for/list ([x (in-range xs xe)])
        (define z (+ y-inc (* x-step x)))
        (let loop ([c z]
                   [z z]
                   [i 0])
          (if (>= i maxIteration)
              0
              (if (>= (magnitude z) escapeRadius)
                  (color-idx c z i)
                  (loop c (+ (* z z) c) (add1 i))))))
      ))
    (place-channel-put pch lls)
    ; Empty list as eof mark
    (place-channel-put pch '())
  )
