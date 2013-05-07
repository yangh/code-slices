#lang racket

(define demo-place
  (lambda ()
    (let ([pls (for/list ([i (in-range 2)])
                 (dynamic-place "place-worker.rkt" 'place-main))])
      (for ([i (in-range 2)]
            [p pls])
        (place-channel-put p i)
        (printf "~a\n" (place-channel-get p)))
      (map place-wait pls))))

(define p (dynamic-place "place-worker.rkt" 'place-main))
(place-channel-put p (list 1000000 2000000 3))
(displayln "do someting and wait...")
(define-values (width height) (values 100000 200000))
(for* ([w width]
       [h height]
       [i width])
  (* (* (* w h) w) h))
(printf "~a\n" (place-channel-get p))
(place-wait p)
