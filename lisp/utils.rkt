#lang racket

; CRC16, refer to qt QBytes->CheckSum()
(define crctbl (list
                #x0000 #x1081 #x2102 #x3183
                #x4204 #x5285 #x6306 #x7387
                #x8408 #x9489 #xa50a #xb58b
                #xc60c #xd68d #xe70e #xf78f))

(define (crc16 data len)
  (define (cacl crc c)
    (bitwise-xor
     (bitwise-and (arithmetic-shift crc -4) #xffff)
     (list-ref crctbl (bitwise-and (bitwise-xor crc c) 15))))
  (let loop ([i 0]
             [crc #xffff])
    (cond
      [(= i len) (bitwise-and (bitwise-not crc) #xffff)]
      [else
       (loop (add1 i) (cacl crc (bytes-ref data i)))])))
