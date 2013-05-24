#lang racket

(require "adb.rkt")

(define adb (new adb%))

(define (le32->number bin)
  (define le-tbl (list 16 1 4096 256))
  1)

(define fb-callback
  (lambda (in out)
    (define fb-info (read-bytes 16 in))
    (printf "Read ~a\n" (bytes-length fb-info))
    (printf "~a\n" (bytes->list fb-info))
    ))

(send adb local-service 'framebuffer "" #:cb fb-callback)