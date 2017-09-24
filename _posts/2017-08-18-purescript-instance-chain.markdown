---
layout: post
title:  "PureScript: Instance chains and Overlapping Instances"
date:   2017-08-18 00:00:00 +0000
categories: purescript instance chain
---

In version `v0.12` the PureScript compiler has support instance chains, and
overlapping instances are an error (previously a warning).

The instance chains feature allows explicit alternation between instances, via
the `else` keyword.  To demonstrate: consider a type class for determining if
two types are equal.

{% highlight haskell %}
class IsEqual
  (l :: Type)
  (r :: Type)
  (b :: Boolean)
  | l r -> b
{% endhighlight %}

Before instance chains, we couldn't implement this properly.  We'd have to use
overlapping instances (or hard-code specific instance-solving into the
complier).  Overlapping instances occurs when there is more than one suitable
instance that could be chosen.

In our example, we'd need a `True` case in which the types match, and a `False`
case for when they don't.

{% highlight haskell %}
instance isEqual0 :: IsEqual l l True

instance isEqual1 :: IsEqual l r False
{% endhighlight %}

But this isn't quite right.  These two instances are overlapping in the case
where the first two type parameters match.  That is, the second instance is
still valid even when the first is.  What previously happened in this scenario
is that the compiler would raise a warning and then pick one of them (by name
order).  Now the compiler will error.

What we can write instead is:

{% highlight haskell %}
instance isEqualRefl :: IsEqual l l True
else
instance isEqualDiff :: IsEqual l r False
{% endhighlight %}

Here the two instances are part of the same declaration, joined by the `else`
keyword.  There can be more than two instances in a chain.

Although this example type class does not have any members, instances in a
chain can each have member implementations specified.

The relationship between instances in a chain is that we will only consider a
later instance if all other instances before it (in the same chain) couldn't
possibly be chosen.

The idea of "couldn't possibly be chosen" is solely based on matching instance
parameters, it does **not** take instance constraints into consideration.

In our example, this means that we will first try to match with the
`isEqualRefl` instance.  Only once we have determined that this can't be chosen
(i.e: the `l` and `r` type parameters do not match) then we try the
`isEqualDiff` instance.

Having alternation between instances will be a very useful tool when computing
at the type level.  I look forward to seeing what people do with it.

You can read the original [instance chain paper here][paper].  In this paper
the authors describe more features than what I have implemented.  Specifically
the instance guards feature has not been implemented.  Nor has syntax for
`fails` been added, but PureScript already has a `Prim.TypeError.Fail` type
class for the same purpose.

[paper]: http://homepages.inf.ed.ac.uk/jmorri14/pubs/morris-icfp2010-instances.pdf

