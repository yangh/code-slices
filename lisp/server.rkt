#lang racket

(define (go)
  (list 'yep-it-works 10 9))

(define (handle in out)
  (regexp-match #rx"(\r\n|^)\r\n" in)
  (display "HTTP/1.0 200 Okay\r\n" out)
  (display "Server: k\r\nContent-Type: text/html\r\n\r\n" out)
  (display "<html><body>Hello, world!</body></html>" out))

(define (accept-and-handle listener)
  (define cust (make-custodian))
  (parameterize ([current-custodian cust])
    (define-values (in out) (tcp-accept listener))
       (thread
	(lambda ()
	 ;;(sleep (random 10))
	 (handle in out)
	 (close-input-port in)
	 (close-output-port out))))
  ;; Watcher thread:
  (thread (lambda ()
	   (sleep 10)
	   (custodian-shutdown-all cust))))

(define (serve port-no)
  (define main-cust (make-custodian))
  (parameterize ([current-custodian main-cust])
    (define listener (tcp-listen port-no 5 #t))
    (define (loop)
     (accept-and-handle listener)
     (loop))
    (thread loop))
  (lambda ()
    (custodian-shutdown-all main-cust)))

