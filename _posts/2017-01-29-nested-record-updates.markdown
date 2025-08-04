---
layout: single
title: "PureScript: Nested Record Updates"
date: 2017-01-29 09:30:00 +0000
categories: purescript records
classes: wide
---

When compiler version 0.10.6 is released, it will include a syntax for nested record updates.

# Problem

Before this change, if we have a nested record structure such as:

{% highlight haskell %}
r = { val: -1
    , level1: { val: -1
              , level2: { val: -1 }
              }
    }
{% endhighlight %}

To update `.level1.val` we'd have to write something like this:

{% highlight haskell %}
r' = r { level1 = r.level1 { val = 1 } }
{% endhighlight %}

This is fairly annoying to write: we need to mention both `r` and `level1` twice.  With even more nesting it just gets worse:

{% highlight haskell %}
r'' = r { level1 = r.level1 { level2 = r.level1.level2 { val = 2 } } }
{% endhighlight %}


# Solution

With the new syntax, the following equivalent expressions are supported:

{% highlight haskell %}
r' = r { level1 { val = 1 } }
r'' = r { level1 { level2 { val = 2 } } }
{% endhighlight %}

To update all the `val` fields it'd look like this:

{% highlight haskell %}
r' = r { val = 0
       , level1 { val = 1
                , level2 { val = 2 }
                }
       }
{% endhighlight %}


# Evaluation

In the previous example we updated an object computed by the expression `r` - which is just a variable.  However if we compute a record by some more complicated expression and then try to update, we wouldn't just blindly substitute the expression in:

{% highlight haskell %}
-- `f r` has been repeated
s = (f r) { level1 = (f r).level1 { val = 1 } }
{% endhighlight %}

Instead we would first compute `f r` and refer to the result twice:

{% highlight haskell %}
s' = let fr = f r in fr { level1 = fr.level1 { val = 1 } }
{% endhighlight %}

When the compiler desugars nested record updates, to prevent reevaluating the object expression, it introduces a `let` binding like the previous example.

