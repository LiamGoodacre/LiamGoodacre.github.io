---
layout: post
title:  "PureScript: Orphan Instance Detection"
date:   2017-01-22 09:37:16 +0000
categories: purescript type class instance orphan functional dependencies
---

For the [0.10.4][psc-0-10-4] release, I worked on upgrading the existing orphan check to take functional dependencies into account.  Before we get into what this means we will need some setup/definitions.

# Setup/Definitions

The head of a type is the top level constructor, for example the head of `Array Int` is `Array`.  In the context of an instance, all the heads of the arguments can be referred to as 'instance heads'.

Functional dependencies are relationships between type class arguments which encode that some arguments can be determined by sets of other arguments.  See [here][psc-fun-deps] for more information.

A covering set is a minimal configuration of type class arguments which, via functional dependencies determining all other arguments, would allow the selection of an instance.  For a given type class with functional dependencies there are potentially many different covering sets.


# Problem

For a given constraint, when searching for type class instances, the PureScript compiler looks at the constraint's supplied arguments.  It finds which modules the head types are defined in and searches those, plus the type-class's module, for suitable instances.  The orphan instance check is about detecting if there are configurations of instance heads in covering sets, such that an instance would have been applicable, except for being defined in a module that we wouldn't know to look in.


# Simple Example

Consider the following type class defined in [purescript-newtype][psc-newtype-class] (skipping the methods):

{% highlight haskell %}
class Newtype t a | t -> a
{% endhighlight %}

The functional dependency describes that if argument `t` is known, then selecting an instance will determine `a`.  That is, we only need to know `t` for instance selection.

As a consequence of this, it means we can only define an instance in either the same module as the type class, or the same module that the type supplied for `t` is defined in.  If the head of `a` is defined in a module that differs from `t` or the type class, then we can't define the instance there - because we don't necessarily know what `a` is when instance searching.

The covering sets in this case are: `{ { t } }`


# More Interesting Example

For the type class:

{% highlight haskell %}
class Foo l r o | l r -> o
{% endhighlight %}

The covering sets are: `{ { l, r } }`

This functional dependency is describing that we need to know both `l` and `r`to find an instance.  That is, `l` and `r` together determine `o`.

This means that for an instance to not be an orphan, it must either:

* be defined with the type class
* or be defined in either the same module as `l`, or the same module as `r` - therefore the head types of `l` and `r` don't have to be defined in the same module

The set of modules we can look in is bigger because there are more arguments we need to know before instance selecting.


# More Complicated Example

For this type class:

{% highlight haskell %}
class Bar l r | l -> r, r -> l
{% endhighlight %}

The covering sets here are: `{ { l }, { r } }`

The arguments `l` and `r` both determine each other.  Thus for instance selection we either need to know a head type for `l` or a head type for `r`.

This means that for an instance to not be an orphan, it must either:

* be defined with the type class - there aren't restrictions on the modules of `l` and `r`
* or be defined in the both the same module as `l` and the same module as `r` - therefore the head types of `l` and `r` must be defined in the same module

The set of modules we can look in is smaller because there are different sets of arguments we could use to find an instance.


# Conclusion

We could come up with even more complicated relationships of type class arguments and produce multiple covering sets with multiple arguments in each.  But the idea is that we intersect the modules for each covering set together (plus the module of the type class) to find the set of modules that the instance is allowed to be defined in.


[psc-0-10-4]: https://github.com/purescript/purescript/releases/tag/v0.10.4
[psc-fun-deps]: https://github.com/paf31/24-days-of-purescript-2016/blob/master/10.markdown
[psc-newtype-class]: https://pursuit.purescript.org/packages/purescript-newtype/1.2.0
