#lang parendown racket/base

; hypermonad.rkt
;
; A generic interface for "hypermonad" type class dictionaries, which
; manipulate hypersnippet-shaped data.

(require #/only-in racket/generic define-generics)

(require #/only-in lathe expect)

(require "../../private/util.rkt")

(provide gen:hypermonad hypermonad? hypermonad/c
  
  hypermonad-hole-hypermonad-for-degree
  
  hypermonad-pure
  hypermonad-bind-with-degree-and-shape
  hypermonad-map-with-degree-and-shape
  hypermonad-join
  
  hypermonad-bind-with-degree
  hypermonad-map-with-degree
)

(provide #/rename-out [make-hypermonad-zero hypermonad-zero])


(define-generics hypermonad
  
  ; This returns a hypermonad where high-degree holes are prohibited.
  ; The valid hypersnippets may be disjoint from this hypermonad's
  ; valid hypersnippets as well.
  (hypermonad-hole-hypermonad-for-degree hypermonad degree)
  
  ; We redundantly cover several monad operations so that they can be
  ; implemented efficiently.
  (hypermonad-pure hypermonad hole-degree hole-shape leaf)
  (hypermonad-bind-with-degree-and-shape
    hypermonad prefix degree-shape-and-leaf-to-suffix)
  (hypermonad-map-with-degree-and-shape
    hypermonad hypersnippet degree-shape-and-leaf-to-leaf)
  (hypermonad-join hypermonad hypersnippets)
  
  ; We provide separate operations for potentially more efficient
  ; variations.
  (hypermonad-bind-with-degree
    hypermonad prefix degree-and-leaf-to-suffix)
  (hypermonad-map-with-degree
    hypermonad hypersnippet degree-and-leaf-to-leaf)
)


; This is a degree-0 hypermonad.
(struct-easy "a hypermonad-zero" (hypermonad-zero)
  #:equal
  #:other
  
  #:constructor-name make-hypermonad-zero
  
  #:methods gen:hypermonad
  [
    
    (define (hypermonad-hole-hypermonad-for-degree this degree)
      (expect this (hypermonad-zero)
        (error "Expected this to be a hypermonad-zero")
      #/expect (exact-nonnegative-integer? degree) #t
        (error "Expected degree to be an exact nonnegative integer")
        (error "Called hypermonad-hole-hypermonad-for-degree on a hypermonad-zero")))
    
    (define (hypermonad-pure this hole-degree hole-shape leaf)
      (expect this (hypermonad-zero)
        (error "Expected this to be a hypermonad-zero")
      #/expect (exact-nonnegative-integer? hole-degree) #t
        (error "Expected hole-degree to be an exact nonnegative integer")
        (error "Called hypermonad-pure on a hypermonad-zero")))
    (define
      (hypermonad-bind-with-degree-and-shape
        this prefix degree-shape-and-leaf-to-suffix)
      (expect this (hypermonad-zero)
        (error "Expected this to be a hypermonad-zero")
      #/expect prefix (list)
        (error "Expected prefix to be an empty list")
      #/list))
    (define
      (hypermonad-map-with-degree-and-shape
        this hypersnippet degree-shape-and-leaf-to-leaf)
      (expect this (hypermonad-zero)
        (error "Expected this to be a hypermonad-zero")
      #/expect hypersnippet (list)
        (error "Expected hypersnippet to be an empty list")
      #/list))
    (define (hypermonad-join this hypersnippets)
      (expect this (hypermonad-zero)
        (error "Expected this to be a hypermonad-zero")
      #/expect hypersnippets (list)
        (error "Expected hypersnippets to be an empty list")
      #/list))
    
    (define
      (hypermonad-bind-with-degree
        this prefix degree-and-leaf-to-suffix)
      (hypermonad-bind-with-degree-and-shape this prefix
      #/lambda (hole-degree hole-shape leaf)
        (degree-and-leaf-to-suffix hole-degree leaf)))
    (define
      (hypermonad-map-with-degree
        this hypersnippet degree-and-leaf-to-leaf)
      (hypermonad-map-with-degree-and-shape this hypersnippet
      #/lambda (hole-degree hole-shape leaf)
        (degree-and-leaf-to-leaf hole-degree leaf)))
  ])


; TODO: See if we'll need these.
(struct-easy "a striped-hypersnippet-nil"
  (striped-hypersnippet-nil island)
  #:equal)
(struct-easy "a striped-hypersnippet-cons"
  (striped-hypersnippet-cons island-and-lakes-and-rest)
  #:equal)

; This is a striped hypermonad alternating between two striped
; hypermonads.
#|
to-hll :: forall holeVals.
  (double-stripe-snippet ii il li) holeVals ->
  (snippet-of ll) holeVals
fill-pred-hole :: forall holeVals.
  (double-stripe-snippet ii il li) (trivial-hole-vals) ->
  (stripe-snippet (snippet-of li) (double-stripe-snippet ii il li)
    ) holeVals ->
  Maybe ((double-stripe-snippet ii il li) holeVals)
fill-pred-pred-hole :: forall holeVals.
  (double-stripe-snippet ii il li) (trivial-hole-vals) ->
  (snippet-of il) holeVals ->
  Maybe ((double-stripe-snippet ii il li) holeVals)
|#
(struct-easy "a hypermonad-striped-striped"
  (hypermonad-striped-striped
    overall-degree hii hil hli hll hl
    to-hll fill-pred-hole fill-pred-pred-hole)
  #:equal
  (#:guard-easy
    (unless (exact-nonnegative-integer? overall-degree)
      (error "Expected overall-degree to be an exact nonnegative integer"))
    (unless (<= 3 overall-degree)
      (error "Expected overall-degree to be 3 or greater")))
  #:other
  
  #:constructor-name make-hypermonad-striped-striped
  
  #:methods gen:hypermonad
  [
    
    (define (hypermonad-hole-hypermonad-for-degree this degree)
      (expect this
        (hypermonad-striped-striped
          overall-degree hii hil hli hll hl
          to-hll fill-pred-hole fill-pred-pred-hole)
        (error "Expected this to be a hypermonad-striped-striped")
      #/expect (exact-nonnegative-integer? degree) #t
        (error "Expected degree to be an exact nonnegative integer")
      #/expect (< degree overall-degree) #t
        (error "Expected degree to be an exact nonnegative integer less than overall-degree")
      #/if (= overall-degree #/add1 degree)
        hl
      #/if (= overall-degree #/add1 #/add1 degree)
        hil
      #/hypermonad-hole-hypermonad-for-degree hii degree))
    
    (define (hypermonad-pure this hole-degree hole-shape leaf)
      (expect this
        (hypermonad-striped-striped
          overall-degree hii hil hli hll hl
          to-hll fill-pred-hole fill-pred-pred-hole)
        (error "Expected this to be a hypermonad-striped-striped")
      #/expect (exact-nonnegative-integer? hole-degree) #t
        (error "Expected hole-degree to be an exact nonnegative integer")
      #/expect (< hole-degree overall-degree) #t
        (error "Expected hole-degree to be an exact nonnegative integer less than overall-degree")
      #/if (= overall-degree #/add1 hole-degree)
        'TODO
      #/if (= overall-degree #/add1 #/add1 hole-degree)
        (hypermonad-pure hii (sub1 hole-degree) 'TODO
        #/hypermonad-map-with-degree-and-shape hil hole-shape
        #/lambda (hole-hole-degree hole-hole-shape leaf)
          (hypermonad-pure hii hole-hole-degree hole-hole-shape leaf))
      #/hypermonad-pure hii hole-degree hole-shape leaf))
    (define
      (hypermonad-bind-with-degree-and-shape
        this prefix degree-shape-and-leaf-to-suffix)
      (expect this
        (hypermonad-striped-striped
          overall-degree hii hil hli hll hl
          to-hll fill-pred-hole fill-pred-pred-hole)
        (error "Expected this to be a hypermonad-striped-striped")
        'TODO))
    (define
      (hypermonad-map-with-degree-and-shape
        this hypersnippet degree-shape-and-leaf-to-leaf)
      (hypermonad-bind-with-degree-and-shape this hypersnippet
      #/lambda (hole-degree hole-shape leaf)
      #/hypermonad-pure this hole-degree hole-shape leaf))
    (define (hypermonad-join this hypersnippets)
      (hypermonad-bind-with-degree-and-shape this hypersnippets
      #/lambda (hole-degree hole-shape hypersnippet)
        hypersnippet))
    
    (define
      (hypermonad-bind-with-degree
        this prefix degree-and-leaf-to-suffix)
      (hypermonad-bind-with-degree-and-shape this prefix
      #/lambda (hole-degree hole-shape leaf)
        (degree-and-leaf-to-suffix hole-degree leaf)))
    (define
      (hypermonad-map-with-degree
        this hypersnippet degree-and-leaf-to-leaf)
      (hypermonad-map-with-degree-and-shape this hypersnippet
      #/lambda (hole-degree hole-shape leaf)
        (degree-and-leaf-to-leaf hole-degree leaf)))
  ])