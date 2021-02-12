#lang parendown scribble/manual

@; punctaffy/scribblings/punctaffy/hypersnippet.scrbl
@;
@; Hypersnippet data structures and interfaces.

@;   Copyright 2020, 2021 The Lathe Authors
@;
@;   Licensed under the Apache License, Version 2.0 (the "License");
@;   you may not use this file except in compliance with the License.
@;   You may obtain a copy of the License at
@;
@;       http://www.apache.org/licenses/LICENSE-2.0
@;
@;   Unless required by applicable law or agreed to in writing,
@;   software distributed under the License is distributed on an
@;   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
@;   either express or implied. See the License for the specific
@;   language governing permissions and limitations under the License.


@(require #/only-in scribble/example examples make-eval-factory)

@(require punctaffy/scribblings/private/shim)

@(shim-require-various-for-label)

@(define example-eval
  (make-eval-factory #/list
    
    'racket/base
    'net/url
    'syntax/datum
    
    'parendown
    
    'punctaffy
    'punctaffy/let
    'punctaffy/quote))

@(define parendown-doc '(lib "parendown/scribblings/parendown.scrbl"))


@(define-syntax-rule @code-block[args ...]
   @nested[#:style 'code-inset]{@verbatim[args ...]})


@title[#:tag "intro"]{Introduction to Punctaffy}

Punctaffy is an experimental library for processing program syntax that has higher-dimensional nested structure.

Most programming languages are designed for programs to be structured in the form of trees, with some (or all) nodes of the tree being delimited using opening and closing brackets. However, occasionally some operations take that a dimension higher, opening with one tree node and closing with some number of tree nodes toward the leaves.

(TODO: Illustrate this graphically.)

This is common with templating languages. For instance, a quasiquotation operation has a quoted body that begins with the initial @racket[`_...] tree node and ends with number of @racket[,_...] and @racket[,@_...] tree nodes. The quasiquotation operation also takes a number of expressions to compute what values should be inserted into those holes in the quoted body, and those expressions are maintained in the same place as the holes their results will be inserted into.

@examples[
  #:label #f
  #:eval (example-eval)
  
  (eval:no-prompt
    (define _site-base-url "https://docs.racket-lang.org/"))
  
  (eval:no-prompt
    (define (_make-sxml-site-link _relative-url _content)
      `(a
         (|@|
           (href
             ,(url->string
                 (combine-url/relative (string->url _site-base-url)
                   _relative-url))))
         ,@_content)))
  
  (_make-sxml-site-link "punctaffy/index.html" '("Punctaffy docs"))
]

Quasiquotation isn't the only example. Connection Machine Lisp (CM-Lisp) is a language that was once used for programming Connection Machine supercomputers, and it has a concept of "xappings," key-value data structures where each element resides on a different processor. It has ways to distribute the same behavior to each processor to transform these values, and it has a dedicated notation to assist with this:

@code-block{
  (defun celsius-to-fahrenheit (c)
    α(+ (* •c 9/5) 32))
  
  (celsius-to-fahrenheit '{low→0 mid→50 high→100})
  ⇒ {low→32 mid→122 high→212}
}

That notation has a body that begins with @tt{α...} node and ends with some number of @tt{•...} nodes. The behavior in between is repeated for each xapping entry.

To make it a bit more mundane for the sake of example, let's suppose the @tt{α} notation works on lists instead of xappings, making it a fancy notation for what a Racket programmer would usually write using @racket[map] or @racket[for/list].

In some programs, the two of them might be used together. Here's some code we can write in Racket today:

@examples[
  #:label #f
  #:eval (example-eval)
  
  (eval:no-prompt
    (define (_make-sxml-unordered-list _items)
      `(ul
        ,@(for/list ([_item (in-list _items)])
            `(li ,_item)))))
  
  (_make-sxml-unordered-list (list "Red" "Yellow" "Green"))
]

Here's the same code, using the @tt{α} operator to do the list mapping operation:

@code-block|{
  (define (make-sxml-unordered-list items)
    `(ul ,@α`(li ,•items)))
}|

In the expression @tt{α@literal{`}(li ,•items)}, we see the @racket[`_...] and @racket[,_...] tree nodes are nested in between the @tt{α...} and @tt{•...} tree nodes.

In Punctaffy's terms, this is the nesting of one degree-2 hypersnippet inside another. It's just like the nesting of one parenthesized region of code inside another, but one dimension higher than usual.

In fact, the geometric shape of a hypersnippet is already studied under a different name: An opetope. Opeteopes are usually studied in higher-dimensional category theory and type theory as one way to work with algebraic structures where two things can be "equal" in more than one distinct way. For instance, in homotopy theory, in the place of equality there's a notion of path-connectedness, and the different "ways" things are path-connected are the various different paths between them.

Our motivation for using these shapes in Punctaffy is different, but it's not a complete coincidence. In a way, the body of a quasiquotation is like the space swept out by the path from the @racket[`_...] tree node to the @racket[,_...] tree nodes, and if we think in terms of fully parenthesized s-expressions, each tree node corresponds to a line drawn from its opening parenthesis to its closing parenthesis.

But Punctaffy is driven by syntax. Let's recall the above example of synthesizing quasiquotaton and apply-to-all notation in a single program:

@code-block|{
  (define (make-sxml-unordered-list items)
    `(ul ,@α`(li ,•items)))
}|

Here we have @racket[`_...] nested inside @tt{α...}. We could also imagine the reverse of this; if we quote a piece of code which uses @tt{α...}, then the @tt{α...} appears nested inside the @racket[`_...].

What does this program do?

@code-block{
  α`(li •,items)
}

This is analogous to writing the program @tt{(while #t (displayln "Hello, world))"}. The delimiters are simply mismatched. We can try to come up with creative interpretations, but there's little reason to use the notations this way in the first place.

So, where do we report the error? Racket's reader doesn't match occurrences of @racket[`_...] to occurrences of @racket[,_...] at read time; instead, these always read successfully as @racket[(quasiquote _...)] and @racket[(unquote _...)], and it's up to the implementation of the @racket[quasiquote] macro to search its tree-shaped input, looking for occurrences of @racket[unquote]. So now do we extend that search so that it keeps track of the proper nesting of @tt{α...} and @tt{•...} hyperbrackets? Does every one of these higher-dimensional operations need to hardcode the grammar of every other?

Currently, in Racket:

@itemlist[
  @item{@racket[quasiquote] only knows to skip nested @racket[quasiquote]..@racket[unquote] pairs}
  
  @item{@racket[quasisyntax] only knows to skip nested @racket[quasisyntax]..@racket[unsyntax] pairs}
  
  @item{@racket[quasisyntax/loc] only knows to skip nested @racket[quasisyntax]..@racket[unsyntax] pairs (but not @racket[quasisyntax/loc]..@racket[unsyntax])}
]

This isn't a problem that usually arises with traditional parentheses. The Racket reader only supports a small set of parentheses, @tt{( ) [ ] { }}, which makes it feasible to hardcode them all. Extending this set is rare; new operations usually just follow the Lispy convention of using the same parentheses as everything else.

What if we did that for higher-dimensional brackets as well, picking a single bracket notation and having most of our operations just use that one? In Punctaffy, we've implemented this approach like so:

Before:

@code-block|{
  (define (make-sxml-unordered-list items)
    `(ul ,@α`(li ,•items)))
}|

After:

@examples[
  #:label #f
  #:eval (example-eval)
  
  (eval:alts
    (eval:no-prompt
      (define (_make-sxml-unordered-list _items)
        (taffy-quote
          (^<
            (ul
              (^>
                (list-taffy-map
                  (^< (taffy-quote (^< (li (^> (list (^> _items))))))))))))))
    #;
    (define (_make-sxml-unordered-list _items)
      (taffy-quote
        (^<
          (ul
            (^>
              (list-taffy-map
                (^< (taffy-quote (^< (li (^> (list (^> _items)))))))))))))
    (define (_make-sxml-unordered-list _items)
      `(ul
        ,@(for/list ([_item (in-list _items)])
            `(li ,_item)))))
]

Welcome to 2-dimensional parenthesis soup. Like s-expression notation, this notation isn't the easiest to follow if we're only concerned with a small number of familiar operations, but it does have the arguable advantage of giving programmers a smoother on-ramp to extending their language: Programmers can add new operations that build on the same infrastructure as the existing ones and blend right in.

We refer to delimiters like @tt{(}@racket[^<] and @tt{(}@racket[^>] as hyperbrackets. There are hyperbrackets of any degree (dimension), and traditional brackets @tt{(} and @tt{)} are a special case of hyperbrackets.

In many cases, we might be able to draw attention to matching hyperbrackets a little bit better by making some judicious use of @other-doc[parendown-doc]:

@examples[
  #:label #f
  #:eval (example-eval)
  
  (eval:alts
    (eval:no-prompt
      (pd _/ define (_make-sxml-unordered-list _items)
        (taffy-quote _/ ^< _/ ul _/ ^>
          (list-taffy-map
            (^<
              (taffy-quote _/ ^< _/ li _/ ^> _/ list
                (^> _items)))))))
    #;
    (pd _/ define (_make-sxml-unordered-list _items)
      (taffy-quote _/ ^< _/ ul _/ ^>
        (list-taffy-map
          (^<
            (taffy-quote _/ ^< _/ li _/ ^> _/ list
              (^> _items))))))
    (define (_make-sxml-unordered-list _items)
      `(ul
        ,@(for/list ([_item (in-list _items)])
            `(li ,_item)))))
]

S-expressions are far from the only option for syntax. Many programming languages have a more elaborate syntax involving infix/prefix/suffix operators, separators, various distinct-looking brackets, and so on.

Likewise, the @tt{(}@racket[^<] and @tt{(}@racket[^>] hyperbracket notation isn't the only conceivable option for working with this kind of higher-dimensional structure.

We expect the same techniques we use in Punctaffy to be useful for parsing other notations that have similar higher-dimensional structure. As an easy example, we could develop a parser for the @racket[`_...] and @tt{α...} notations we originally used above.

A more curious example is a template DSL that already exists in Racket, which is almost tailor-made for the exact situation:

@examples[
  #:label #f
  #:eval (example-eval)
  
  (eval:no-prompt
    (define (_make-sxml-unordered-list _items)
      (with-datum ([(_item ...) _items])
        (datum (ul (li _item) ...)))))
]

In Racket's @racket[datum] template DSL, occurrences of @racket[...] cause an item to be repeated some number of times, just like using @tt{α}. A template variable like @racket[_item] is statically associated with an ellipsis depth that governs how many ellipses must be applied to it. In this case, @racket[_item] has an ellipsis depth of 1, so wherever it appears in a template, it implicitly behaves like @tt{•items}. (If the iteration depth were 4, it would behave like @tt{••••items}.) Meanwhile, unbound identifiers like @racket[_ul] and @racket[_li] are implicitly quoted, and miscellaneous syntactic landmarks are implicitly quoted as well. For instance, the lists which surround @racket[_ul] and @racket[_li] are quoted as though they were surrounded with @tt{@literal{`}} and @tt|{,@}|.

In the process of explaining how Racket's template DSL works, we've described a *translation* of (a subset of) that DSL into other Racket code. Maybe @tt{α...} and @tt{•...} aren't actually implemented in Racket, but Punctaffy does implement @racket[(list-taffy-map (^< _...))] and @racket[(^> _...)] to serve their purpose here.

A common technique for DSLs in Racket is first to use a parser to preprocess a DSL into a similarly shaped Racket s-expression, then to expand it using a suite of Racket macros. In this case, what we've described isn't a translation into a mere s-expression so much as a translation into hyperbracketed code. In this way, regardless of the experience of using hyperbrackets directly, hyperbrackets provide infrastructure that can be helpful in the implementation of other DSLs.



@section[#:tag "terminology"]{Terminology}

(TODO: This section used to be the main blurb for the Punctaffy documentation. It's still where we introduce quite a bit of the terminology. We'd like to go over this at some point in case some parts don't quite fit the documentation's current flow.)

Punctaffy is a library implementing and exploring hypersnippets, a higher-dimensional generalization of lexical hierarchical structure. For instance, theoretically, Punctaffy can be good for manipulating data that contains expanded macro bodies whose internal details should be independent from both the surrounding code and the code they interpolate. Structural recursion using Punctaffy's data representations makes it easy to keep these local details local, just as traditional forms of structural recursion make it easy to keep branches of a tree data structure from interfering with unrelated branches.

So how does this make any sense? We can think of the macro bodies as being @emph{more deeply nested}, despite the fact that the code they interpolate still appears in a nested position as far as the tree structure of the code is concerned. In this sense, the tree structure is not the full story of the nesting of the code.

This is a matter of @emph{dimension}, and we can find an analogous situation one dimension down: The content between two parentheses is typically regarded as further into the traversal of the tree structure of the code, despite the fact that the content following the closing parenthesis is still further into the traversal of the code's text stream structure. The text stream is not the full story of how the code is meant to be traversed.

Punctaffy has a few particular data structures that it revolves around.

A @deftech{hypersnippet}, or a @deftech{snippet} for short, is a region of code that's bounded by lower-degree snippets. The @deftech{degree} of a snippet is typically a number representing its dimension in a geometric sense. For instance, a degree-3 snippet is bounded by degree-2 snippets, which are bounded by degree-1 snippets, which are bounded by degree-0 snippets, just as a 3D cube is bounded by 2D squares, which are bounded by 1D line segments, which are bounded by 0D points. One of the boundaries of a hypersnippet is the opening delimiter. The others are the closing delimiters, or the @deftech{holes} for short. This name comes from the idea that a degree-3 snippet is like an expression (degree-2 snippet) with expression-shaped holes.

While a degree-3 snippet primarily has degree-2 holes, it's also important to note that its degree-2 opening delimiter has degree-1 holes, and the degree-1 opening delimiter of that opening delimiter has a degree-0 hole. Most Punctaffy operations traverse the holes of every dimension at once, largely just because we've found that to be a useful approach.

The idea of a hypersnippet is specific enough to suggest quite a few operations, but the actual content of the code contained @emph{inside} the snippet is vague. We could say that the content of the code is some sequence of bytes or some Unicode text, but we have a lot of options there, and it's worth generalizing over them so that we don't have to implement a new library each time. So the basic operations of a hypersnippet are represented in Punctaffy as generic operations that multiple data structures might be able to implement.

Snippets don't identify their own snippet nature. Instead, each hypersnippet operation takes a @deftech{hypersnippet system} (aka a @deftech{snippet system}) argument, and it uses that to look up the appropriate hypersnippet functionality.

A @deftech{dimension system} is a collection of implementations of the arithmetic operations we need on dimension numbers. (A @deftech{dimension number} is the "3" in the phrase "degree-3 hypersnippet." It generally represents the set of smaller dimension numbers that are allowed for a snippet's @tech{holes}.) For what we're doing so far, it turns out we only need to compare dimension numbers and take their maximum. For some purposes, it may be useful to use dimension numbers that aren't quite numbers in the usual sense, such as dimensions that are infinite or symbolic.

@; TODO: See if we should mention hyperstacks right here. It seems like they can be skipped in this high-level overview since they're more of an implementation aid.

A hypersnippet system always has some specific dimension system it's specialized for. We tend to find that notions of hypersnippet make sense independently of a specific dimension system, so we sometimes represent these notions abstractly as a kind of functor from a dimesion system to a snippet system. In practical terms, a functor like this lets us convert between two snippet systems that vary only in their choice of dimension system, as long as we have some way to convert between the dimension systems in question.

A @deftech{hypertee} is a kind of hypersnippet data structure that represents a region of code that doesn't contain content of any sort at all. A hypertee may not have content, but it still has a boundary, and hypertees tend to arise as the description of the @tech{shape} of a hypersnippet. For instance, when we try to graft a snippet into the hole of another snippet, it needs to have a shape that's compatible with the shape of that hole.

A @deftech{hypernest} is a kind of hypersnippet data structure that generalizes some other kind of hypersnippet (typically hypertees) by adding @deftech{bumps}. Bumps are like @tech{holes} that are already filled in, but with a seam showing. The filling, called the bump's @deftech{interior}, is considered to be nested deeper than the surrounding content. A bump can contain other bumps. A bump can also contain holes of degree equal to or greater than the bump's degree.

A hypernest is a generalization of an s-expression or other syntax tree. In an s-expression, the bumps are the pairs of parentheses and the atoms. In a syntax tree, the bumps are the nodes. Just as trees are rather effective representations of lots of different kinds of structured programs and structured data, so are hypernests, and that makes them Punctaffy's primary hypersnippet data structure.


@; TODO: Consider using the following explanation for something. I think it builds up to the point too slowly to be a useful introduction to hypersnippets, but it might turn out to be just the explanation someone needs. Maybe now that we've laid out the main themes of Punctaffy above, this can be part of a more gradual explanation. Let's also consider how the readme factors into all this.

@;{

At some level, program code is often represented with text streams. This is a one-dimensional representation of syntax; when we talk about a snippet of text, we designate a beginning point and an ending point and talk about the text that falls in between.

Instead of treating the program as a text stream directly, most languages conceive of it as taking on a tree structure, like an s-expression, a Racket syntax object, a concrete syntax tree, or a skeleton tree. Even later stages of program analysis tend to be modeled as trees (in this case, abstract syntax trees). The notion of a "program with holes" tends to refer to a tree where some of the branches are designated as blanks to be filled in later.

A "program with holes" in that sense is very much analogous to a snippet of text: It begins with a root node and ends with any number of hole nodes, and we talk about the nodes in between.

As s-expressions make explicit, a node in a concrete syntax tree tends to correspond to a pair of parentheses in the text stream. So each node is a snippet between points in the text, and a program with holes is the content that falls in between one root snippet and some number of hole snippets. It's a 2-dimensional snippet.

The dimensions of a higher-dimensional snippet are roughly analogous to those of a geometric shape. A location in a text stream is like a geometric point, a snippet of text is like a line segment bounded by two points, and a program-with-holes is like a polygon bounded by line segments.

As with geometric shapes, we can look toward higher dimensions: A 3-dimensional snippet is bounded by an outer program-with-holes and some arrangement of inner programs-with-holes. A 4-dimensional snippet is bounded by 3-dimensional snippets. We coin the term "hypersnippet" to suggest this tower of generalization.

Higher-dimensional geometric shapes often have quite a number of component vertices and line segments, and the jumble can be a bit awkward to visualize. The same is true to some extent with hypersnippets, but as full of detail as they can get, they're still ultimately bounded by some collection of locations in a text stream. Because of this, we can visualize their shapes using sequences of unambiguously labeled brackets positioned at those points.

}
