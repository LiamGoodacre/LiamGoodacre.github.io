---
layout: single
title:  "PureScript: Deriving Functor"
date:   2017-01-23 08:00:00 +0000
categories: purescript functor deriving
---

For the [0.10.4][psc-0-10-4] release, I worked on `Functor` deriving.  This allows you to write a data type and derive a `Functor` instance for it.  This obviously doesn't work for all data types, but also doesn't necessarily work for all data types that could have a valid `Functor` instance written for them.  In this post I will demonstrate examples of the kinds of structures it works for, and those it doesn't.

Recall the definition of the `Functor` type class:

{% highlight haskell %}
class Functor f where
  map :: forall a. (a -> b) -> f a -> f b
{% endhighlight %}

Given a data type `F :: * -> *`, to derive the `Functor` instance, we would write a derived instance such as:

{% highlight haskell %}
derive instance functorF :: Functor F
{% endhighlight %}

If the compiler is able to compute the implementation of `map` for the particular `F` data type, then it will do so; otherwise you will get a bad type error.  We have a ticket to improve the error message [here][psc-issue-derive-functor-error].

The following is a collection of example data types for which this deriving mechanism should work for.  Each with a short comment describing the particular arrangement of types that is being demonstrated.

{% highlight haskell %}
-- no mention of index
data Const c x = Const c

-- mention of index as argument
data Identity x = Identity x

-- index as multiple arguments
data Two x = Two x x

-- index as arguments across constructors
data Which x = This x | That x

-- index in records
data Rec x = Rec { field0 :: x, field1 :: x }

-- index nested under other functor types
data Wrapped x = Wrapped (Boolean -> Array x)

-- recursive
data List x = Nil | Cons x (List x)

-- dependency on functor of other argument
data Free f x = Pure x | Free (f (Free f x))
derive instance functorFreeF :: Functor f => Functor (Free f)
{% endhighlight %}

Note that the last example also requires a `Functor` instance on the index `f`.  If we omitted this, we would end up with the type error similar to:

```
No type class instance was found for

    Data.Functor.Functor f

```


# Algorithm

Implementing the `map` function is rather straight-forward.  For each argument in each constructor:

* if the argument is the type index, then apply the mapping function
* if the argument is a record, then recurse on each field
* if the argument is a type application, recurse on the argument and wrap the function in a call to `map`
* otherwise, leave the argument alone

Records are somewhat *special* in PureScript, so we decided to add a special case for them.


# Limitations

Given this algorithm, we can see some obvious limitations: we only recurse on the last argument in a type application - so we may miss the uses of the index in other argument positions.

We also only ever assume a `Functor` instance for a data type with the argument in the last index.  If we have some contravariant data type `C :: * -> *` and a data type `data F x = F (C (C x))`, with this algorithm we are unable to derive a `Functor F` instance, even though a valid one exists via `cmap <<< cmap`.

Each of these limitations could potentially be overcome by a more interesting algorithm with access to more information about the types involved: such as index variance tracking.  With variance tracking we could compute which sort of mapping to apply: `map`, `cmap`, `bimap`, `dimap`, etc.


# Conclusion

Aside from those limitations, with such a simple algorithm we gained a useful and widely applicable code generating tool.  As a next step, and following a similar algorithm, we would like to derive `Foldable` and `Traversable` (ticket [here][psc-issue-foldable-traversable]).  Perhaps I will work on those some time soon if someone else doesn't beat me to it :)

[psc-0-10-4]: https://github.com/purescript/purescript/releases/tag/v0.10.4
[psc-issue-derive-functor-error]: https://github.com/purescript/purescript/issues/2519
[psc-issue-foldable-traversable]: https://github.com/purescript/purescript/issues/2518
