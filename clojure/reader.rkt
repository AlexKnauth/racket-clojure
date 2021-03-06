#lang racket/base

(provide wrap-reader make-clojure-readtable current-syntax-introducer make-intro)

(require racket/port
         racket/set
         syntax/readerr
         version/utils
         "reader/parse-afl.rkt"
         )

(define (make-clojure-readtable [rt (current-readtable)])
  (make-readtable rt
                  #\~ #\, #f
                  #\, #\space #f
                  #\_ 'dispatch-macro s-exp-comment-proc
                  #\[ 'terminating-macro vec-proc
                  #\{ 'terminating-macro hash-proc
                  #\{ 'dispatch-macro set-proc
                  #\\ 'non-terminating-macro char-proc
                  #\: 'non-terminating-macro kw-proc
                  #\( 'dispatch-macro afl-proc
                  ))

(define (s-exp-comment-proc ch in src ln col pos)
  (make-special-comment (read-syntax/recursive src in)))

(define (vec-proc ch in src ln col pos)
  (define lst-stx
    (parameterize ([read-accept-dot #f])
      (read-syntax/recursive src in ch (make-readtable (current-readtable) ch #\[ #f))))
  (define lst (syntax->list lst-stx))
  (datum->syntax lst-stx (list->immutable-vector lst) lst-stx lst-stx))

(define (list->immutable-vector lst)
  (apply vector-immutable lst))

(define (hash-proc ch in src ln col pos)
  (define lst-stx
    (parameterize ([read-accept-dot #f])
      (read-syntax/recursive src in ch (make-readtable (current-readtable) ch #\{ #f))))
  (define lst (syntax->list lst-stx))
  (unless (even? (length lst))
    (raise-read-error "hash map literal must contain an even number of forms"
                      src ln col pos (syntax-span lst-stx)))
  (datum->syntax lst-stx (for/hash ([(k v) (in-hash (apply hash lst))]) ; need syntax property to
                           (values (syntax->datum k) v))                ; preserve order of evaluation
    lst-stx                                                             ; and source locations of keys
    (syntax-property lst-stx 'clojure-hash-map lst-stx)))

(define (set-proc ch in src ln col pos)
  (define lst-stx
    (parameterize ([read-accept-dot #f])
      (read-syntax/recursive src in ch (make-readtable (current-readtable) ch #\{ #f))))
  (datum->syntax lst-stx (list->set (syntax->datum lst-stx))
    lst-stx
    (syntax-property lst-stx 'clojure-set lst-stx)))

(define (char-proc ch in src ln col pos)
  (define in*
    (parameterize ([port-count-lines-enabled #t])
      (input-port-append #f (open-input-string "\\") in)))
  (set-port-next-location! in* ln col pos)
  (read-syntax/recursive src in* #\# #f))

(define (kw-proc ch in src ln col pos)
  (define id-stx
    (read-syntax/recursive src in ch (make-readtable (current-readtable) ch #\: #f)))
  (syntax-property id-stx 'clojure-keyword #t))

(define (afl-proc ch in src ln col pos)
  (define lst-stx
    (read-syntax/recursive src in ch))
  (parse-afl lst-stx))

(define (wrap-reader rd)
  (lambda args
    (define intro (make-intro))
    (parameterize ([current-readtable (make-clojure-readtable)]
                   [current-syntax-introducer intro])
      (define stx (apply rd args))
      (if (and (syntax? stx) (version<=? "6.2.900.4" (version)))
          (intro stx)
          stx))))

