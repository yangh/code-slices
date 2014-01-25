#lang racket  ; mud

(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(define listener (tcp-listen 12345 4 #t #f))

(define (change-merged)
  (displayln "Start building..."))

(let mud-server-loop ()
  (define-values (in out) (tcp-accept listener))

  (thread
     (lambda ()
      (let loop ([line ""])
       (cond
         [(eof-object? line)
          (displayln "Disconnected")
          (close-output-port out)]
         [else
          (displayln line)
          (flush-output)
          ; TODO: parse and call instead eval
          (eval (read (open-input-string line)) ns)
          (flush-output)
          (loop (read-line in))]))))
  (mud-server-loop))

