#lang parendown racket/base

; punctaffy/hypersnippet/hypernest
;
; A data structure for encoding hypersnippet notations that can nest
; with themselves.

;   Copyright 2018 The Lathe Authors
;
;   Licensed under the Apache License, Version 2.0 (the "License");
;   you may not use this file except in compliance with the License.
;   You may obtain a copy of the License at
;
;       http://www.apache.org/licenses/LICENSE-2.0
;
;   Unless required by applicable law or agreed to in writing,
;   software distributed under the License is distributed on an
;   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
;   either express or implied. See the License for the specific
;   language governing permissions and limitations under the License.


(require #/only-in racket/contract/base
  -> any any/c list/c listof or/c)
(require #/only-in racket/contract/region define/contract)

(require #/only-in lathe-comforts
  dissect dissectfn expect fn mat w- w-loop)
(require #/only-in lathe-comforts/list list-kv-map list-map)
(require #/only-in lathe-comforts/maybe
  just maybe? maybe/c maybe-map nothing)
(require #/only-in lathe-comforts/struct istruct/c struct-easy)
(require #/only-in lathe-comforts/trivial trivial)
(require #/only-in lathe-ordinals
  onum<=? onum<? onum-max 0<onum<=omega? onum<=omega? onum<omega?
  onum-omega)
(require #/only-in lathe-ordinals/olist olist-build)

(require #/only-in punctaffy/hypersnippet/hyperstack
  make-pushable-hyperstack pushable-hyperstack-dimension
  pushable-hyperstack-pop pushable-hyperstack-push)
(require #/only-in punctaffy/hypersnippet/hypertee
  degree-and-closing-brackets->hypertee hypertee? hypertee-contour
  hypertee-degree hypertee-drop1 hypertee-dv-all-all-degrees
  hypertee-dv-any-all-degrees hypertee-dv-each-all-degrees
  hypertee-dv-join-all-degrees-selective hypertee-each-all-degrees
  hypertee-filter hypertee-get-hole-zero
  hypertee-join-selective-interpolation
  hypertee-join-selective-non-interpolation hypertee-map-all-degrees
  hypertee<omega? hypertee-promote hypertee-pure hypertee-set-degree
  hypertee-truncate hypertee-zip-selective)

(provide
  (struct-out hypernest-bump)
  (struct-out hypernest-hole)
  hypernest-bracket-degree
  (rename-out
    [-hypernest? hypernest?]
    [-hypernest-degree hypernest-degree])
  degree-and-hypertees->hypernest
  hypernest->degree-and-hypertees
  degree-and-brackets->hypernest
  hypernest-promote
  hypernest-set-degree
  hypernest<omega?
  hypertee->hypernest
  hypernest->maybe-hypertee
  hypernest-truncate-to-hypertee
  hypernest-contour
  hypernest-zip
  (struct-out hypernest-drop1-result-zero)
  (struct-out hypernest-drop1-result-hole)
  (struct-out hypernest-drop1-result-bump)
  hypernest-drop1
  hypernest-map-all-degrees
  hypernest-pure
  hypernest-join-all-degrees
  hypernest-bind-all-degrees
  hypernest-bind-one-degree
  hypernest-join-one-degree
  hypernest-plus1)


; ===== Hypernests ===================================================

(struct-easy (hypernest-bump value interior) #:equal)
(struct-easy (hypernest-hole value) #:equal)


(define/contract (hypernest-bracket-degree bracket)
  (->
    (or/c
      onum<omega?
      (list/c onum<omega? any/c)
      (list/c 'open 0<onum<=omega? any/c))
    onum<omega?)
  (mat bracket (list 'open d data)
    d
  #/mat bracket (list d data)
    d
    bracket))

(define/contract
  (hypernest-brackets->hypernest-hypertees
    opening-degree hypernest-brackets)
  (->
    onum<=omega?
    (listof #/or/c
      onum<omega?
      (list/c onum<omega? any/c)
      (list/c 'open 0<onum<=omega? any/c))
    (maybe/c hypertee?))
  (begin (displayln "blah d1") (writeln opening-degree) (writeln hypernest-brackets)
  #/mat opening-degree 0
    (expect hypernest-brackets (list)
      (error "Expected hypernest-brackets to be empty for a hypernest of degree zero")
    #/nothing)
  #/just
  #/w- root-i 'root
  #/w-loop next
    
    hypernest-brackets-remaining
    (list-kv-map hypernest-brackets #/fn k v #/list k v)
    
    interiors (hash-set (make-immutable-hasheq) root-i (list))
    
    hist
    (list (just root-i)
      (make-pushable-hyperstack
      #/olist-build opening-degree #/dissectfn _ #/nothing))
    
    (dissect hist (list maybe-state histories)
    #/expect hypernest-brackets-remaining
      (cons hypernest-bracket hypernest-brackets-remaining)
      (expect (pushable-hyperstack-dimension histories) 0
        (error "Expected more closing brackets")
      #/expect maybe-state (nothing)
        (error "Internal error: Reached the end without being in the degree-zero hole")
      #/w-loop next i root-i
        (degree-and-closing-brackets->hypertee (onum-omega)
        #/list-map (reverse #/hash-ref interiors i) #/fn bracket
          (expect bracket (list d #/hypernest-bump bump-value i)
            bracket
          #/list d #/hypernest-bump bump-value #/next i)))
    #/dissect hypernest-bracket (list new-i bracket)
    #/mat bracket (list 'open d bump-value)
      (expect maybe-state (just state)
        (error "Encountered an opening bracket inside a hole")
      #/w- interiors (hash-set interiors new-i (list))
      #/w- interiors
        (hash-update interiors state #/fn rev-brackets
          (cons (list d #/hypernest-bump bump-value new-i)
            rev-brackets))
      #/next hypernest-brackets-remaining interiors
        (list (just new-i)
          (pushable-hyperstack-push histories
          #/olist-build d #/dissectfn _ #/just state)))
    #/w- d (hypernest-bracket-degree bracket)
    #/expect (onum<? d #/pushable-hyperstack-dimension histories) #t
      (begin (displayln "blah d2") (writeln bracket) (writeln d) (writeln #/pushable-hyperstack-dimension histories)
      #/error "Encountered a closing bracket of degree higher than the current region's degree")
    #/dissect
      (pushable-hyperstack-pop histories
      #/olist-build d #/dissectfn _ maybe-state)
      (list popped-barrier restored-maybe-state restored-history)
    #/w- interiors
      (mat maybe-state (just state)
        (mat restored-maybe-state (just restored-state)
          (w- interiors
            (hash-update interiors restored-state #/fn rev-brackets
              (cons bracket rev-brackets))
          #/mat popped-barrier 'push
            (mat bracket (list d hole-value)
              (raise-arguments-error
                'hypernest-brackets->hypernest-hypertees
                "expected a closing bracket that returned from a bump to have no associated data value"
                "opening-degree" opening-degree
                "hypernest-brackets" hypernest-brackets
                "bracket" bracket)
            #/hash-update interiors state #/fn rev-brackets
              (cons (list bracket #/hypernest-hole #/trivial)
                rev-brackets))
          #/dissect popped-barrier 'pop
            (mat bracket (list d hole-value)
              (error "Expected a closing bracket that resumed a bump to have no associated data value")
            #/hash-update interiors state #/fn rev-brackets
              (cons bracket rev-brackets)))
          (mat popped-barrier 'root
            (expect bracket (list d hole-value)
              (error "Expected a closing bracket that began a hole to be annotated with a data value")
            #/hash-update interiors state #/fn rev-brackets
              (cons (list d #/hypernest-hole hole-value) rev-brackets))
          #/dissect popped-barrier 'pop
            (mat bracket (list d hole-value)
              (error "Expected a closing bracket that continued a hole to have no associated data value")
            #/hash-update interiors state #/fn rev-brackets
              (cons bracket rev-brackets))))
        (mat restored-maybe-state (just restored-state)
          (dissect popped-barrier 'pop
          #/mat bracket (list d hole-value)
            (error "Expected a closing bracket that ended a hole to have no associated data value")
          #/hash-update interiors restored-state #/fn rev-brackets
            (cons bracket rev-brackets))
          (error "Internal error: Went directly from a hole to another hole")))
    #/next hypernest-brackets-remaining interiors
      (list restored-maybe-state restored-history))))

; TODO: Implement this.
#;
(define/contract
  (hypernest-hypertees->hypernest-brackets opening-degree hypertees)
  (-> onum<=omega? (maybe/c hypertee?)
    (listof #/or/c
      onum<omega?
      (list/c onum<omega? any/c)
      (list/c 'open 0<onum<=omega? any/c)))
  'TODO)

(define/contract (assert-valid-hypernest-hypertees degree hypertees)
  (-> onum<=omega? (maybe/c hypertee?) void?)
  (expect hypertees (just hypertees)
    (expect degree 0
      (error "Expected a hypernest with no hypertees to have degree zero")
    #/void)
  #/mat degree 0
    (error "Expected a degree-zero hypernest to have no hypertees")
  #/expect (equal? (onum-omega) #/hypertee-degree hypertees) #t
    (error "Expected a hypernest's hypertee's dimension to be omega")
  #/hypertee-each-all-degrees hypertees #/fn hole data
    (mat data (hypernest-hole hole-value)
      ; NOTE: We don't validate `hole-value`.
      (expect (onum<? (hypertee-degree hole) degree) #t
        (raise-arguments-error 'assert-valid-hypernest-hypertees
          "expected each of a hypernest's holes to be of degree less than its own"
          "degree" degree
          "hole-degree" (hypertee-degree hole)
          "hypertees" hypertees
          "hole" hole
          "data" data)
      #/void)
    #/mat data (hypernest-bump bump-value interior)
      ; NOTE: We don't validate `bump-value`.
      (w-loop next hole hole interior interior
        (mat (hypertee-degree hole) 0
          (error "Expected a bump to have a degree greater than zero")
        #/expect (equal? (onum-omega) #/hypertee-degree interior) #t
          (error "Expected a bump's interior's hypertee dimension to be omega")
        #/expect
          (hypertee-zip-selective hole interior
            (fn hole data
              (mat data (hypernest-hole hole-value)
                (expect hole-value (trivial)
                  (error "Expected a bump's interior's hypernest hole's data value to be a trivial value")
                  #t)
              #/mat data (hypernest-bump bump-value interior)
                ; NOTE: We don't validate `bump-value`.
                (begin (next bump-value interior)
                  #f)
              #/error "Expected a bump's interior's hypertee holes to contain hypernest-bump and hypernest-hole values"))
          #/fn hole hole-data interior-data
            (trivial))
          (just zipped)
          (error "Expected a bump's interior to have the same shape as the hypertee hole that contained it")
        #/void))
    #/raise-arguments-error 'assert-valid-hypernest-hypertees
      "expected a hypernest's hypertee holes to contain hypernest-bump and hypernest-hole values"
      "hypertees" hypertees
      "data" data)))

; TODO: Give this a custom writer that uses a sequence-of-brackets
; representation.
(struct-easy (hypernest degree hypertees)
  #:equal
  (#:guard-easy
    (assert-valid-hypernest-hypertees degree hypertees)))

; A version of `hypernest?` that does not satisfy
; `struct-predicate-procedure?`.
(define/contract (-hypernest? v)
  (-> any/c boolean?)
  (hypernest? v))

; A version of the `hypernest` constructor that does not satisfy
; `struct-constructor-procedure?`.
(define/contract (degree-and-hypertees->hypernest degree hypertees)
  (-> onum<=omega? (maybe/c hypertee?) hypertee?)
  ; TODO: See if we can improve the error messages so that they're
  ; like part of the contract of this procedure instead of being
  ; thrown from inside the `hypernest` constructor.
  (hypernest degree hypertees))

(define/contract (degree-and-brackets->hypernest degree brackets)
  (->
    onum<=omega?
    (listof #/or/c
      onum<omega?
      (list/c onum<omega? any/c)
      (list/c 'open 0<onum<=omega? any/c))
    hypernest?)
  ; TODO: See if we can improve the error messages so that they're
  ; like part of the contract of this procedure instead of being
  ; thrown from inside `hypernest-brackets->hypernest-hypertees` and
  ; the `hypernest` constructor.
  (hypernest degree
  #/hypernest-brackets->hypernest-hypertees degree brackets))

; A version of `hypernest-degree` that does not satisfy
; `struct-accessor-procedure?`.
(define/contract (-hypernest-degree hn)
  (-> hypernest? onum<=omega?)
  (dissect hn (hypernest d hypertees)
    d))

(define/contract (hypernest->degree-and-hypertees hn)
  (-> hypertee? #/list/c onum<=omega? #/maybe/c hypertee?)
  (dissect hn (hypernest d hypertees)
  #/list d hypertees))

; TODO: Uncomment this once `hypernest-hypertees->hypernest-brackets`
; has been implemented.
#;
(define/contract (hypernest->degree-and-brackets hn)
  (-> hypertee?
    (list/c onum<=omega?
    #/listof #/or/c
      onum<omega?
      (list/c onum<omega? any/c)
      (list/c 'open 0<onum<=omega? any/c)))
  (dissect hn (hypernest d hypertees)
  #/list d #/hypernest-hypertees->hypernest-brackets d hypertees))

; Takes a hypernest of any degree N and upgrades it to any degree N or
; greater, while leaving its bumps and holes the way they are.
(define/contract (hypernest-promote new-degree hn)
  (-> onum<=omega? hypernest? hypernest?)
  (dissect hn (hypernest d hypertees)
  #/expect (onum<=? d new-degree) #t
    (raise-arguments-error 'hypernest-promote
      "expected hn to be a hypernest of degree no greater than new-degree"
      "new-degree" new-degree
      "hn" hn)
  #/hypernest new-degree hypertees))

; Takes a hypernest with no holes of degree N or greater and returns a
; degree-N hypernest with the same bumps and holes.
(define/contract (hypernest-set-degree new-degree hn)
  (-> onum<=omega? hypernest? hypernest?)
  (dissect hn (hypernest d hypertees)
  #/begin
    (unless (onum<=? d new-degree)
      (dissect hypertees (just hypertees)
      #/hypertee-dv-each-all-degrees hypertees #/fn d data
        (expect data (hypernest-hole data) (void)
        #/unless (onum<? d new-degree)
          (raise-arguments-error 'hypernest-set-degree
            "expected hn to have no holes of degree new-degree or greater"
            "hn" hn
            "new-degree" new-degree
            "hole-degree" d
            "data" data))))
  #/hypernest new-degree hypertees))

(define/contract (hypernest<omega? v)
  (-> any/c boolean?)
  (and (hypernest? v) (onum<omega? #/hypernest-degree v)))

(define/contract (hypertee->hypernest ht)
  (-> hypertee? hypernest?)
  (w- d (hypertee-degree ht)
  #/mat d 0 (hypernest 0 #/nothing)
  #/hypernest d #/just #/hypertee-promote (onum-omega)
  #/hypertee-map-all-degrees ht #/fn hole data
    (hypernest-hole data)))

(define/contract (hypernest->maybe-hypertee hn)
  (-> hypernest? #/maybe/c hypertee?)
  (dissect hn (hypernest d maybe-hypertees)
  #/expect maybe-hypertees (just hypertees)
    (just #/degree-and-closing-brackets->hypertee d #/list)
  #/expect
    (hypertee-dv-all-all-degrees hypertees #/fn d data
      (mat data (hypernest-hole data) #t #f))
    #t
    (nothing)
  #/just #/hypertee-set-degree d
  #/hypertee-map-all-degrees hypertees #/fn hole data
    (dissect data (hypernest-hole data)
      data)))

(define/contract (hypernest-truncate-to-hypertee hn)
  (-> hypernest? hypertee?)
  (dissect hn (hypernest d maybe-hypertees)
  #/expect maybe-hypertees (just hypertees)
    (degree-and-closing-brackets->hypertee d #/list)
  #/hypertee-map-all-degrees
    (hypertee-filter (hypertee-truncate d hypertees) #/fn hole data
      (mat data (hypernest-hole data) #t #f))
  #/fn hole data
    (dissect data (hypernest-hole data)
      data)))

; Takes a hypertee of any degree N and returns a hypernest of degree
; N+1 with all the same degree-less-than-N holes as well as a single
; degree-N hole in the shape of the original hypertee. This should
; be useful as something like a monadic return.
(define/contract (hypernest-contour hole-value ht)
  (-> any/c hypertee<omega? hypernest?)
  (hypertee->hypernest #/hypertee-contour hole-value ht))

; This zips a degree-N hypertee with a same-degree-or-higher hypernest
; if they have the same holes when certain holes of the hypernest are
; removed -- namely, the holes of degree N or greater and the holes
; that don't match the given predicate.
(define/contract
  (hypernest-zip-selective smaller bigger should-zip? func)
  (->
    hypertee?
    hypernest?
    (-> hypertee? any/c boolean?)
    (-> hypertee? any/c any/c any/c)
    (maybe/c hypernest?))
  (dissect bigger (hypernest d-bigger maybe-hypertees)
  #/expect (onum<=? (hypertee-degree smaller) d-bigger) #t
    (error "Expected smaller to be a hypertee of degree no greater than bigger's degree")
  #/expect maybe-hypertees (just hypertees) bigger
  #/maybe-map
    (hypertee-zip-selective smaller hypertees
      (fn hole data
        (expect data (hypernest-hole data) #f
        #/should-zip? hole data))
      (fn hole smaller-data bigger-data
        (dissect bigger-data (hypernest-hole bigger-data)
        #/hypernest-hole #/func hole smaller-data bigger-data)))
  #/fn zipped
  #/hypernest d-bigger #/just zipped))

; This zips a degree-N hypertee with a same-degree-or-higher hypernest
; if they have the same holes when truncated to degree N.
(define/contract (hypernest-zip-low-degrees smaller bigger func)
  (-> hypertee? hypernest? (-> hypertee? any/c any/c any/c)
    (maybe/c hypernest?))
  (hypernest-zip-selective smaller bigger (fn hole data #t) func))

(define/contract (hypernest-zip ht hn func)
  (-> hypertee? hypernest? (-> hypertee? any/c any/c any/c)
    (maybe/c hypernest?))
  (expect (equal? (hypertee-degree ht) (hypernest-degree hn)) #t
    (error "Expected the hypertee and the hypernest to have the same degree")
  #/hypernest-zip-low-degrees ht hn func))

(struct-easy (hypernest-drop1-result-zero) #:equal)
(struct-easy (hypernest-drop1-result-hole data tails) #:equal)
(struct-easy (hypernest-drop1-result-bump data tails) #:equal)

(define/contract (hypernest-drop1 hn)
  (-> hypernest?
    (or/c
      (istruct/c hypernest-drop1-result-zero)
      (istruct/c hypernest-drop1-result-hole any/c hypertee?)
      (istruct/c hypernest-drop1-result-bump any/c hypernest?)))
  
  (define (blah-fn args body)
    (w- tagline
      (apply string-append " blah"
        (list-map args #/fn arg
          (format " ~a" arg)))
    #/begin (displayln #/format "/~a" tagline)
    #/begin0 (body)
    #/begin (displayln #/format "\\~a" tagline)))
  
  (define-syntax-rule (blah arg ... body)
    (blah-fn (list arg ...) (lambda () body)))
  
  (blah "e0"
  #/dissect hn (hypernest d maybe-hypertees)
  #/expect maybe-hypertees (just hypertees)
    (hypernest-drop1-result-zero)
  #/dissect (hypertee-drop1 hypertees) (just #/list data tails)
  #/blah "e0.1"
  #/mat data (hypernest-hole data)
    (blah "e0.2"
    #/hypernest-drop1-result-hole data
    #/hypertee-map-all-degrees tails #/fn hole tail
      (w- root-hole-degree (hypertee-degree hole)
      ; We build a hypernest out of the tail, replacing the tail's
      ; low-degree holes, which contain `(trivial)`, with
      ; `(hypernest-hole #/trivial)`.
      #/hypernest d #/just
      #/blah "e0.3"
      #/hypertee-map-all-degrees tail #/fn hole data
        (blah "e0.4"
        #/expect (onum<? (hypertee-degree hole) root-hole-degree) #t
          data
        #/dissect data (trivial)
        #/hypernest-hole #/trivial)))
  #/dissect data (hypernest-bump data interior)
  #/dissect
    (blah "e1"
    #/hypernest-zip
      (blah "e2"
      #/hypertee-map-all-degrees tails #/fn hole tail
        (w- root-hole-degree (hypertee-degree hole)
        #/hypernest (onum-max d root-hole-degree) #/just
        #/hypertee-map-all-degrees tail #/fn hole data
          (expect (onum<? (hypertee-degree hole) root-hole-degree) #t
            data
          #/dissect data (trivial)
          #/hypernest-hole #/trivial)))
      (blah "e3" interior
      #/hypernest (hypertee-degree tails) #/just interior)
    #/fn hole tail interior-data
      (dissect interior-data (trivial)
        tail))
    (just interior)
  #/hypernest-drop1-result-bump data interior))

; TODO IMPLEMENT: Implement operations analogous to these:
;
;   hypertee-fold
;   hypertee-dv-join-all-degrees-selective

; TODO IMPLEMENT: Implement operations analogous to this, but for
; bumps instead of holes.
(define/contract (hypernest-map-all-degrees hn func)
  (-> hypernest? (-> hypertee<omega? any/c any/c) hypernest?)
  (dissect hn (hypernest d maybe-hypertees)
  #/expect maybe-hypertees (just hypertees) hn
  #/hypernest d #/just
  #/hypertee-map-all-degrees hypertees #/fn hole data
    (expect data (hypernest-hole data) data
    #/hypernest-hole #/func hole data)))

; TODO IMPLEMENT: Implement operations analogous to these:
;
;   hypertee-map-one-degree
;   hypertee-map-pred-degree
;   hypertee-map-highest-degree

(define/contract (hypernest-pure degree data hole)
  (-> onum<=omega? any/c hypertee<omega? hypernest?)
  (hypernest-promote degree #/hypernest-contour data hole))

(define/contract (hypernest-get-hole-zero hn)
  (-> hypernest? maybe?)
  (dissect hn (hypernest degree maybe-hypertees)
  #/maybe-map maybe-hypertees #/fn hypertees
  #/dissect (hypertee-get-hole-zero hypertees)
    (just #/hypernest-hole data)
    data))

; TODO IMPLEMENT: Implement operations analogous to these:
;
;   hypertee-bind-pred-degree
;   hypertee-bind-highest-degree

; TODO IMPLEMENT: Implement operations analogous to this, but for
; bumps instead of holes.
(define call-no 0)
(define/contract (hypernest-join-all-degrees hn)
  (-> hypernest? hypernest?)
  
  (define (blah-fn args body)
    (w- tagline
      (apply string-append " blah"
        (list-map args #/fn arg
          (format " ~a" arg)))
    #/begin (displayln #/format "/~a" tagline)
    #/begin0 (body)
    #/begin (displayln #/format "\\~a" tagline)))
  
  (define-syntax-rule (blah arg ... body)
    (blah-fn (list arg ...) (lambda () body)))
  
  (begin
    (set! call-no (add1 call-no))
    (displayln "***** blah l1")
    (writeln call-no)
;    (when (equal? 39 call-no)
;      (error "blah"))
  #/blah "l2" hn
  #/dissect hn (hypernest d maybe-hypertees)
  #/hypernest d #/maybe-map maybe-hypertees #/fn hypertees
    (hypertee-dv-join-all-degrees-selective
    #/hypertee-map-all-degrees hypertees #/fn hole data
      (w- root-hole-degree (hypertee-degree hole)
      #/expect data (hypernest-hole interpolation)
        (hypertee-join-selective-non-interpolation data)
      #/expect interpolation
        (hypernest interpolation-d maybe-hypertees)
        (raise-arguments-error 'hypernest-join-all-degrees
          "expected each interpolation to be a hypernest"
          "hn" hn
          "root-hole" hole
          "interpolation" interpolation)
      #/expect (equal? d interpolation-d) #t
        (raise-arguments-error 'hypernest-join-all-degrees
          "expected each interpolation to be a hypernest of the same degree as the root"
          "hn" hn
          "root-hole" hole
          "interpolation" interpolation)
      #/dissect maybe-hypertees (just hypertees)
      #/hypertee-join-selective-interpolation
      #/hypertee-map-all-degrees hypertees #/fn hole data
        (expect (onum<? (hypertee-degree hole) root-hole-degree) #t
          (hypertee-join-selective-non-interpolation data)
        #/expect data (hypernest-hole data)
          (hypertee-join-selective-non-interpolation data)
        #/expect data (trivial)
          (error "Expected each low-degree hole of each interpolation to contain a trivial value")
        #/hypertee-join-selective-interpolation #/trivial)))))

; TODO IMPLEMENT: Implement operations analogous to this, but for
; bumps instead of holes.
(define/contract (hypernest-bind-all-degrees hn hole-to-hn)
  (-> hypernest? (-> hypertee<omega? any/c hypernest?) hypernest?)
  (hypernest-join-all-degrees
  #/hypernest-map-all-degrees hn hole-to-hn))

; TODO IMPLEMENT: Implement operations analogous to this, but for
; bumps instead of holes.
(define/contract (hypernest-bind-one-degree degree hn func)
  (-> onum<omega? hypernest? (-> hypertee<omega? any/c hypernest?)
    hypernest?)
  (hypernest-bind-all-degrees hn #/fn hole data
    (if (equal? degree #/hypertee-degree hole)
      (func hole data)
      (hypernest-pure (hypernest-degree hn) data hole))))

; TODO IMPLEMENT: Implement operations analogous to this, but for
; bumps instead of holes.
(define/contract (hypernest-join-one-degree degree hn)
  (-> onum<omega? hypernest? hypernest?)
  (hypernest-bind-one-degree degree hn #/fn hole data
    data))

; TODO IMPLEMENT: Implement operations analogous to this, but for
; bumps instead of holes.
(define/contract (hypernest-dv-any-all-degrees hn func)
  (-> hypernest? (-> onum<omega? any/c any/c) any/c)
  (dissect hn (hypernest degree maybe-hypertees)
  #/expect maybe-hypertees (just hypertees) #f
  #/hypertee-dv-any-all-degrees hypertees #/fn d data
    (expect data (hypernest-hole data) #f
    #/func d data)))

; TODO IMPLEMENT: Implement operations analogous to these:
;
;   hypertee-v-any-one-degree
;   hypertee-any-all-degrees
;   hypertee-dv-all-all-degrees
;   hypertee-all-all-degrees

; TODO IMPLEMENT: Implement operations analogous to this, but for
; bumps instead of holes.
(define/contract (hypernest-dv-each-all-degrees hn body)
  (-> hypernest? (-> onum<omega? any/c any) void?)
  (hypernest-dv-any-all-degrees hn #/fn d data #/begin
    (body d data)
    #f)
  (void))

; TODO IMPLEMENT: Implement operations analogous to these:
;
;   hypertee-v-each-one-degree
;   hypertee-each-all-degrees

(define/contract (hypernest-plus1 degree drop1-result)
  (->
    onum<=omega?
    (or/c
      (istruct/c hypernest-drop1-result-zero)
      (istruct/c hypernest-drop1-result-hole any/c hypertee?)
      (istruct/c hypernest-drop1-result-bump any/c hypernest?))
    hypernest?)
  
  (define (blah-fn args body)
    (w- tagline
      (apply string-append " blah"
        (list-map args #/fn arg
          (format " ~a" arg)))
    #/begin (displayln #/format "/~a" tagline)
    #/begin0 (body)
    #/begin (displayln #/format "\\~a" tagline)))
  
  (define-syntax-rule (blah arg ... body)
    (blah-fn (list arg ...) (lambda () body)))
  
  (blah "g1"
  #/mat drop1-result (hypernest-drop1-result-zero)
    (expect degree 0
      (error "Expected the degree to be zero since the drop1-result was a hypernest-drop1-result-zero")
    #/hypernest 0 #/nothing)
  #/mat degree 0
    (error "Expected the degree to be nonzero since the drop1-result wasn't a hypernest-drop1-result-zero")
  #/mat drop1-result (hypernest-drop1-result-hole data tails)
    (blah "g2"
    #/expect (onum<? (hypertee-degree tails) degree) #t
      (raise-arguments-error 'hypernest-plus1
        "expected tails to be a hypertee with degree less than the given degree"
        "tails" tails
        "tails-degree" (hypertee-degree tails)
        "degree" degree)
    #/begin
      (hypertee-dv-each-all-degrees tails #/fn d tail
        (unless
          (and
            (hypernest? tail)
            (equal? degree #/hypernest-degree tail))
          (error "Expected tails to be a hypertee with hypernests of the same degree in all its holes")))
    #/begin
      (hypertee-dv-each-all-degrees tails #/fn d tail
        (hypernest-dv-each-all-degrees tail #/fn d2 data
          (when (onum<? d2 d)
          #/expect data (trivial)
            (raise-arguments-error 'hypernest-plus1
              "expected tails to be a hypertee containing hypernests such that a hypernest in a hole of degree N contained only trivial values at degrees less than N"
              "tails" tails
              "tails-hole-degree" d
              "tail" tail
              "tail-hole-degree" d2
              "data" data)
          #/void)))
    #/blah "g2.1"
    #/hypernest-join-all-degrees #/hypernest-pure degree
      (hypernest-pure degree data
      #/hypertee-map-all-degrees tails #/fn hole tail
        (trivial))
      tails)
  #/dissect drop1-result (hypernest-drop1-result-bump data tails)
    (blah "g3"
    #/mat degree 0
      (error "Expected degree to be nonzero since drop1-result was a hypernest-drop1-result-bump")
    #/begin
      (hypernest-dv-each-all-degrees tails #/fn d tail
        (unless (hypernest? tail)
          (error "Expected tails to be a hypernest with hypernests in all its holes")))
    #/begin
      (hypernest-dv-each-all-degrees tails #/fn d tail
        (unless (equal? (onum-max degree d) (hypernest-degree tail))
          (raise-arguments-error 'hypernest-plus1
            "expected tails to be a hypernest containing hypernests that were each of the overall degree or of the same degree as the hole they were in, whichever was greater"
            "overall-degree" degree
            "tails" tails
            "tails-hole-degree" d
            "tail" tail)))
    #/begin
      (hypernest-dv-each-all-degrees tails #/fn d tail
        (hypernest-dv-each-all-degrees tail #/fn d2 data
          (when (onum<? d2 d)
          #/expect data (trivial)
            (raise-arguments-error 'hypernest-plus1
              "expected tails to be a hypernest containing hypernests such that a hypernest in a hole of degree N contained only trivial values at degrees less than N"
              "tails" tails
              "tails-hole-degree" d
              "tail" tail
              "tail-hole-degree" d2
              "data" data)
          #/void)))
    #/w- trivial-tails
      (hypernest-map-all-degrees tails #/fn hole tail
        (trivial))
    #/w- truncated-tails (hypernest-truncate-to-hypertee tails)
    #/blah "g3.1"
    #/hypernest-set-degree degree
    #/blah "g3.2"
    #/hypernest-join-all-degrees
    #/blah "g4"
    #/hypernest (onum-omega) #/just
    #/blah "g5"
    #/hypertee-pure (onum-omega)
      (hypernest-hole
      #/hypernest (onum-omega) #/just
      #/hypertee-pure (onum-omega)
        (hypernest-bump data
        #/dissect trivial-tails (hypernest _ #/just tails-hypertees)
          tails-hypertees)
      #/hypertee-map-all-degrees truncated-tails #/fn hole tail
        (hypernest-hole #/trivial))
    #/hypertee-map-all-degrees truncated-tails #/fn hole tail
      (hypernest-hole #/hypernest-promote (onum-omega) tail))))

; TODO IMPLEMENT: Implement operations analogous to these:
;
;   hypertee-contour?
;   hypertee-uncontour
;   hypertee-filter
;   hypertee-truncate