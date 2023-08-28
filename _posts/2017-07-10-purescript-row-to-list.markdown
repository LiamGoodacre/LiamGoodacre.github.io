---
layout: single
title:  "PureScript: RowToList"
date:   2017-07-10 20:52:31 +0000
categories: purescript rows records
---

I recently added the `RowToList` and `ListToRow` type classes to the 2.3.0
release of the [typelevel-prelude][typelevel-prelude] under the `Type.Row`
module.  The idea with these two type classes is to be able to compute at the
type-level with rows of types.  This is achieved by converting to/from a
type-level cons-list:

{% highlight haskell %}
foreign import kind RowList
foreign import data Nil :: RowList
foreign import data Cons :: Symbol -> Type -> RowList -> RowList
{% endhighlight %}

This describes that entries in a `RowList` are pairs of symbols and types.

The `RowToList` type class converts from a row of types to a `RowList`. It is
solved by the compiler (as of version 0.11.6) and is defined as:

{% highlight haskell %}
class RowToList (row :: # Type)
                (list :: RowList) |
                row -> list
{% endhighlight %}

It extracts the collection of entries in a closed row of types.
The list of entries is sorted by label but preserves order of duplicates.

Here are a few examples with a given input row and the computed `RowList`:

{% highlight haskell %}
RowToList () Nil

RowToList (a :: A) (Cons "a" A Nil)

RowToList (b :: B, a :: A) (Cons "a" A (Cons "b" B Nil))

RowToList (a :: A0, b :: B, a :: A1) (Cons "a" A0 (Cons "a" A1 (Cons "b" B Nil)))
{% endhighlight %}

The (almost) inverse of this operation is `ListToRow` - which takes a `RowList`
and computes a row of types from it.  This type class is straight-forwardly
defined by recursively applying a `RowCons`:

{% highlight haskell %}
class ListToRow (list :: RowList)
                (row :: # Type) |
                list -> row

instance listToRowNil
  :: ListToRow Nil ()

instance listToRowCons
  :: ( ListToRow tail tailRow
     , RowCons label ty tailRow row )
=> ListToRow (Cons label ty tail) row
{% endhighlight %}

Note that a `RowList` need not have sorted keys for `ListToRow` to produce a
row.  The list produced by `RowToList row list` should produce the same `row`
when passed to `ListToRow list row`, but not necessarily the other way around.

## Example

A good demonstration of the kinds of things we can do with these type classes
is an `applyRecord` function.  This will accept a record of functions and a
record of inputs, producing a record of outputs.  Such that each key in the
input and the output may have distinct types.

First we'll write out the type of `applyRecord`:

{% highlight haskell %}
applyRecord :: forall io i o.
  ApplyRecord io i o =>
  Record io -> Record i -> Record o
{% endhighlight %}

Here I'm using `i`, `o`, and `io` to indicate input, output, and functions from
input to output; respectively.

Now for the type class:

{% highlight haskell %}
class ApplyRecord (io :: # Type)
                  (i :: # Type)
                  (o :: # Type)
                  | i o -> io
                  , io o -> i
                  , io i -> o
{% endhighlight %}

Notice all those functional dependencies.  To be able to compute the any of
these types we need to know the other two.

There's only one instance of the above type class, and it's a fairly
straight-forward conversion of each of the rows to `RowList`, then delegate to
an `ApplyRowList` type class, and finally convert back to row.  The conversions
are constrained to be inverses of each other.

{% highlight haskell %}
instance applyRecordImpl
  :: ( RowToList io lio
     , RowToList i li
     , RowToList o lo
     , ApplyRowList lio li lo
     , ListToRow lio io
     , ListToRow li i
     , ListToRow lo o )
  => ApplyRecord io i o
{% endhighlight %}

The `ApplyRowList` is (as you might expect) a version of `ApplyRecord`, except
instead of working with rows of types, it works with `RowList`.

{% highlight haskell %}
class ApplyRowList (io :: RowList)
                   (i :: RowList)
                   (o :: RowList)
                   | i o -> io
                   , io o -> i
                   , io i -> o
{% endhighlight %}

Almost exactly the same as the previous type class, just working at a different
kind.

Now that we have list representations of the rows, we can recursively process
them!  The first case to deal with is `Nil`.  Remember that all the records
must have the same keys.  So when we hit `Nil`, they must all be `Nil`:

{% highlight haskell %}
instance applyRowListNil
  :: ApplyRowList Nil Nil Nil
{% endhighlight %}

Very easy.

Next up is the `Cons` case.  Again all three lists must be `Cons` at the same
time.  Not only that, but they must have the same keys in the same order.

{% highlight haskell %}
instance applyRowListCons
  :: ApplyRowList tio ti to
  => ApplyRowList (Cons k (i -> o) tio) (Cons k i ti) (Cons k o to)
{% endhighlight %}

Notice the relationship between the entries here: `i -> o`, `i`, and `o`.

As an instance constraint, we recursively compute on the tails of each `Cons`.

...and we're done!  At least the type computation part.  We could write
`applyRecord` with the FFI - which I'll leave out as an implementation detail.

To demonstrate that this works, here are a few examples:

{% highlight haskell %}
-- setup

foo :: {a :: Boolean -> String, b :: Int -> Boolean}
foo = {a: show, b: (_ > 0)}

bar :: {a :: Boolean, b :: Int}
bar = {a: true, b: 0}

-- examples

eg0 x = applyRecord foo x
eg1 x = applyRecord x bar
eg2 r = applyRecord r.io r.i
{% endhighlight haskell %}

{% highlight haskell %}
-- With types equivalent to the following being inferred:

eg0 :: forall i o.
  ApplyRecord (a :: Boolean -> String, b :: Int -> Boolean) i o =>
  Record i -> Record o

eg1 :: forall io o.
  ApplyRecord io (a :: Boolean, b :: Int) o =>
  Record io -> Record o

eg2 :: forall io i.
  ApplyRecord io i (a :: String, b :: Boolean) =>
  { io :: Record io, i :: Record i } ->
  { a :: String, b :: Boolean }
{% endhighlight %}

## Conclusion

Hopefully this has given you some insight into how the `RowToList` and
`ListToRow` type classes have given us super powers in dealing with rows.  For
example, we can now define `Show` and `Eq` instances for records!

I look forward to seeing all the fun things people do with this :)

## Update 2017-09-24

In the previous version of this post I had the fundeps as:

{% highlight haskell %}
| io -> i o
, i -> io o
, o -> io i
{% endhighlight %}

This was incorrect, for example knowing just the input can't tell you the
output.

[typelevel-prelude]: https://github.com/purescript/purescript-typelevel-prelude
