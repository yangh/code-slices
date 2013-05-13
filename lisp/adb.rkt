#lang racket

; printf("%0{len}x", n)
(define (number->hexstring n len)
  (define hex (format "~X" n))
  (define remd (- len (string-length hex)))
  (string-append (make-string remd #\0) hex))

(define adb%
  (class object%
    (init-field [my-devices ""])
    
    (super-new)

    (define host "localhost")
    (define port 5037)
    
    (define/public (connect host port)
      ;(TODO "connect to given host:port")
      (define c-in #f)
      (define c-out #f)
      (set!-values (c-in c-out) (tcp-connect host port)))
    
    (define (read-payload fd)
      (define hexstr (read-string 4 fd))
      (define len (string->number hexstr 16))
      (define pld (read-string len fd))
      (values len pld))

    (define (sendquery cmd fd)
      (display (number->hexstring (string-length cmd) 4) fd)
      (display cmd fd)
      (flush-output fd)
      #t)
 
    (define (read-status c-in)
      (define status (read-string 4 c-in))
      ;(printf "Status: ~a\n" status)
      (cond
        [(equal? status "OKAY")
         (values #t "")]
        [(equal? status "FAIL")
         (define-values (len msg) (read-payload c-in))
         (values #f (string-append "Protocol error: " msg))]
        [else
         (values #f (string-append "Unknown status: " status))]))

    (define (switch-socket-transport in out)
      ; TODO: Add more transport type as needed
      (define cmd "host:transport-any")
      (sendquery cmd out)
      (read-status in))

    (define (query cmd func)
      (with-handlers ([exn:fail:network?
                       (lambda (errno) ; TODO: more detailed error info
                         (displayln "Failed to connect adb server"))])
        (define-values (c-in c-out) (tcp-connect host port))
        (printf "Connected, do query: ~a\n" cmd)

        (when (not (equal? "host" (substring cmd 0 4)))
          ;TODO check switch result
          (switch-socket-transport c-in c-out))

        (sendquery cmd c-out)
        (define-values (status msg) (read-status c-in))
        (cond
          [status (func c-in c-out)]
          [else   (displayln msg)])
        (close-input-port c-in)
        (close-output-port c-out)
      ))

    (define/public (devices)
      (define cmd "host:devices")
      (query cmd
             (lambda (in out)
               (define-values (len dlist) (read-payload in))
               ;(displayln "Devices:")
               (display dlist))))

    (define/public (shell argv)
      (define cmd (string-append "shell:" argv))
      (query cmd
             (lambda (in out)
               (let loop ([fd in])
                 (define line (read-line fd))
                 (when (not (eof-object? line))
                   (display line)
                   (loop fd))))
             ))
    ))

(define adb (new adb%))
;(send adb connect "localhost" 5037)
(send adb devices)
;(send adb shell "logcat")
(send adb shell "ls /system/bin/sh")
    