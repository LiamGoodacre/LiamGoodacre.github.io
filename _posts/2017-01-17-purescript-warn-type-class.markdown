---
title: "PureScript: Warn type class"
date: 2017-01-17 21:30:16 +0000
categories: purescript warnings
---

I recently added user defined warnings to the [PureScript][psc]
compiler.  This feature will be available in the release following `0.10.5`.
You can find the feature request [here][issue-warn].


## Definition

To print a warning during compilation, we added a type class called `Warn`.  It
is located in the `Prim` module and is defined as:

{% highlight haskell %}
class Warn (message :: Symbol)
{% endhighlight %}

It is indexed by a `Symbol` - you can read about symbols [here][psc-symbols].


## Use

If this type class is used as a constraint in a type, for example:

{% highlight haskell %}
-- inspired by the example on the feature request
trace :: Warn "Do not use 'trace' in production code"
      => forall a. String -> a -> a
{% endhighlight %}

When this function is used and the compiler starts solving for the constraints,
it will trivially solve the `Warn` instance and print out the message.


## Example

Another use case is a deprecation message with upgrade instructions:

{% highlight haskell %}
fromList :: Warn "Deprecated `fromList`, use `fromFoldable` instead."
         => forall a. List a -> Foo a

fromFoldable :: forall f a. Foldable f => f a -> Foo a
{% endhighlight %}

I've written about this on the [documentation repo][docs-warn].

[psc]: https://github.com/purescript/purescript
[issue-warn]: https://github.com/purescript/purescript/issues/2564
[psc-symbols]: https://github.com/paf31/24-days-of-purescript-2016/blob/master/9.markdown
[docs-warn]: https://github.com/purescript/documentation/blob/master/guides/Custom-Type-Errors.md
