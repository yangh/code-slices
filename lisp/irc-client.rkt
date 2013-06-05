#lang racket
; A simple IRC client wrote in Racket

(define irc-client%
  (class object%
    (init-field host port)
    (super-new)
    
    (define in #f)
    (define out #f)
    
    (define (process-msg msg)
      (define parts (string-split msg))
      (cond
        [(equal? "PING" (car parts))
         (printf "PONG ~a\n" (car (cdr parts)))
         (action (format "PONG ~a\r\n" (second parts)))]
        [else
         (displayln msg)]))

    (with-handlers ([exn:fail:network?
                     (lambda (errno) ; TODO: more detailed error info
                       (displayln "Failed to connect to server"))])
      (printf "Connecting to ~a:~a\n" host port)
      (set!-values (in out) (tcp-connect host port))
      (printf "Connected\n")

      (thread (lambda ()
                (let loop ([in in])
                  (define data (read-line in))
                  (cond
                    [(eof-object? data)
                     (displayln "Disconnected.")]
                    [else
                     ;(printf "Read ~a\n" (string-length data))
                     (process-msg (string-trim data))
                     (loop in)])))))

    (define/public (action msg)
      (display msg out)
      (flush-output out))
    ))

(define irc (new irc-client%
                 [host "irc.freenode.net"]
                 [port 8001]))

(send irc action "CAP LS\r\n")
(send irc action "NICK H0ngHong\r\n")
(send irc action "USER HongHong123 H0ngHong irc.freenode.net :HongHong\r\n")

; This procedure is required by freenode
(sleep 2)
(send irc action "CAP REQ :identify-msg\r\n")
(sleep 2)
(send irc action "CAP END\r\n")

(sleep 2)
(send irc action "JOIN ##lpc\r\n")
(sleep 30)
;(displayln "end of app")