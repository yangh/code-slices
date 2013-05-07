#lang racket

(provide place-main)

(define (place-main pch)
  (let* ([args (place-channel-get pch)]
         [width  (list-ref args 0)]
         [height (list-ref args 1)]
         [xs     (list-ref args 2)]
         [xe     (list-ref args 3)]
         [ys     (list-ref args 4)]
         [ye     (list-ref args 5)]
         [Q1     (list-ref args 6)]
         [Q2     (list-ref args 7)]
         [escapeRadius (list-ref args 8)]
         [maxIteration    (list-ref args 9)]
         [buffered	(list-ref args 10)])
    (define x-step (make-rectangular (/ (abs (real-part (- Q1 Q2))) (sub1 width)) 0))
    (define y-step (make-rectangular 0 (/ (abs (imag-part (- Q1 Q2))) (sub1 height))))

    (define logEscapeRadius (log escapeRadius))

    (define (color-idx c z i)
      (define mu ( - i (/ (log (log (magnitude (+ (* z z) c)))) logEscapeRadius)))
      ; shit
      (define idx (inexact->exact (round (real-part (* (/ mu maxIteration) 768)))))
      ;(displayln idx)
      (if (or (>= idx 768) (< idx 0))
          0
          idx))

    ;(printf "step (~a, ~a)\n" x-step y-step)
    ;(define mark (if (> ys 0) "." "*"))
    (define mark (make-bytes 1 (+ 97 (/ ys (- ye ys)))))

    (define lls
      (for/list ([ y (in-range ys ye)])
        (define y-inc (- Q1 (* y-step y)))
        ; trace
        (display mark)
        (flush-output)
        (for/list ([x (in-range xs xe)])
          (define z (+ y-inc (* x-step x)))
          (let loop ([c z]
                     [z z]
                     [i 0])
            (if (>= i maxIteration)
                0
                (if (>= (magnitude z) escapeRadius)
                    (color-idx c z i)
                    (loop c (+ (* z z) c) (add1 i))))
        ))
      ))
    (place-channel-put pch lls)
    ; Empty list as eof mark
    (place-channel-put pch '())
    (place-channel-put pch '())
  ))

