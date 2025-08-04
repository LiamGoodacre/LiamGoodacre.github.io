---
layout: single
title: "Functor Picking"
date: 2023-08-28T13:22:16,798428869+01:00
classes: wide
---

## Picking the Output

Imagine you need to come up with a program of type:

$$\begin{align}
  & = F \rightsquigarrow \text{Q}
\end{align}$$

aka

$$\begin{align}
  & = \forall\ x\ . F\ x \rightarrow \text{Q}\ x
\end{align}$$

Where, \\(F\\) is a fixed \\(\text{Functor}\\), but you get to pick \\(\text{Q}\\).

What different choices could you make, and what effect can they have?

There are some straight-forward choices...

Render the computation pointless with \\(\text{Proxy}\\):

$$\begin{align}
  & = F \rightsquigarrow \text{Proxy} \\
  & = \forall\ x\ . F\ x \rightarrow \text{Unit} \\
  & = \text{Unit}
\end{align}$$

Select an \\(x\\) out of \\(F\\) with \\(\text{Identity}\\).

$$\begin{align}
  & = F \rightsquigarrow \text{Identity} \\
  & = \forall\ x\ . F\ x \rightarrow \text{Identity}\ x \\
  & = \forall\ x\ . F\ x \rightarrow x
\end{align}$$

Refute \\(F\\) with \\(\text{Const}\ \text{Void}\\).

$$\begin{align}
  & = F \rightsquigarrow \text{Const}\ \text{Void} \\
  & = \forall\ x\ . F\ x \rightarrow \text{Const}\ \text{Void}\ x \\
  & = \forall\ x\ . F\ x \rightarrow \text{Void}
\end{align}$$

Or, indeed, return whatever you like with \\(\text{Const}\\).

$$\begin{align}
  & = F \rightsquigarrow \text{Const}\ \text{KmettFanFiction}
\end{align}$$

Implement two functions at once via a product (\\(\text{\_} \times \text{\_}\\)):

$$\begin{align}
  & = F \rightsquigarrow (\text{H} \times \text{G}) \\
  & = \forall\ x\ . F\ x \rightarrow (\text{H} \times \text{G})\ x \\
  & = \forall\ x\ . F\ x \rightarrow (\text{H}\ x \times \text{G}\ x) \\
  & = (\forall\ x\ . F\ x \rightarrow \text{H}\ x) \times (\forall\ x\ . F\ x \rightarrow \text{G}\ x) \\
  & = (F \rightsquigarrow \text{H}) \times (F \rightsquigarrow \text{G})
\end{align}$$

Add another input via \\(\text{ReaderT}\\):

$$\begin{align}
  & = F \rightsquigarrow \text{ReaderT}\ \text{Config}\ \text{H} \\
  & = \forall\ x\ . F\ x \rightarrow \text{ReaderT}\ \text{Config}\ \text{H}\ x \\
  & = \forall\ x\ . F\ x \rightarrow \text{Config} \rightarrow \text{H}\ x \\
  & = \text{Config} \rightarrow \forall\ x\ . F\ x \rightarrow \text{H}\ x \\
  & = \text{Config} \rightarrow F \rightsquigarrow \text{H}
\end{align}$$

Tweaking this slightly we can introduce:

```haskell
newtype (^) g f x = Exp (f x -> g x)
```

Then the new input can also refer to the quantification variable:

$$\begin{align}
  & = F \rightsquigarrow (\text{H} \mathrel{\hat{}} \text{G}) \\
  & = \forall\ x\ . F\ x \rightarrow (\text{H} \mathrel{\hat{}} \text{G})\ x \\
  & = \forall\ x\ . F\ x \rightarrow \text{G}\ x \rightarrow \text{H}\ x \\
  & = \forall\ x\ . (F\ x \times \text{G}\ x) \rightarrow \text{H}\ x \\
  & = \forall\ x\ . (F \times \text{G})\ x \rightarrow \text{H}\ x \\
  & = (F \times \text{G}) \rightsquigarrow \text{H}
\end{align}$$

Conveniently remember that the input isn't just \\(F\\), it's \\(F \circ \text{G}\\), via Ran by \\(\text{G}\\) (\\(\text{\_}/\text{G}\\)):

$$\begin{align}
  & = F \rightsquigarrow (\text{H} / \text{G}) \\
  & = \forall\ x\ . F\ x \rightarrow (\text{H} / \text{G})\ x \\
  & = \forall\ x\ . F\ x \rightarrow (\forall\ y\ . (x \rightarrow \text{G}\ y) \rightarrow \text{H}\ y) \\
  & = \forall\ x\ y\ . F\ x \rightarrow (x \rightarrow \text{G}\ y) \rightarrow \text{H}\ y \\
  & = \forall\ y\ . (\exists\ x\ . (F\ x,\ x \rightarrow \text{G}\ y)) \rightarrow \text{H}\ y \\
  & = \forall\ y\ . \text{Coyoneda}\ F\ (\text{G}\ y) \rightarrow \text{H}\ y \\
  & = \forall\ y\ . F\ (\text{G}\ y) \rightarrow \text{H}\ y \\
  & = \forall\ y\ . (F \circ \text{G})\ y \rightarrow \text{H}\ y \\
  & = F \circ \text{G} \rightsquigarrow \text{H}
\end{align}$$

Ah it's actually an \\(F\\)-algebra on \\(\text{C}\\), via \\(\text{Cont}\\):

$$\begin{align}
  & = F \rightsquigarrow \text{Cont}\ \text{C} \\
  & = \forall\ x\ . F\ x \rightarrow \text{Cont}\ \text{C}\ x \\
  & = \forall\ x\ . F\ x \rightarrow (x \rightarrow \text{C}) \rightarrow \text{C} \\
  & = (\exists\ x\ . (F\ x,\ x \rightarrow \text{C})) \rightarrow \text{C} \\
  & = \text{Coyoneda}\ F\ \text{C} \rightarrow \text{C} \\
  & = F\ \text{C} \rightarrow \text{C}
\end{align}$$

Go mad and combine them in interesting ways:

$$\begin{align}
  & = F \rightsquigarrow ((\text{Cont}\ \text{A} / \text{B}) \times \text{ReaderT}\ \text{C}\ \text{D}) \\
  & = (F\ (\text{B}\ \text{A}) \rightarrow \text{A}) \times (\text{C} \rightarrow F \rightsquigarrow \text{D})
\end{align}$$


## Picking the Input

Now suppose things were the other way around, and instead of picking \\(\text{Q}\\) in:

$$\begin{align}
  & = F \rightsquigarrow \text{Q}
\end{align}$$

We only get to pick the \\(\text{F}\\):

$$\begin{align}
  & = \text{F} \rightsquigarrow Q
\end{align}$$

Like with products before, we can still implement multiple functions, but this
time we'll need to use coproducts (\\(\text{\_} + \text{\_}\\)):

$$\begin{align}
  & = (\text{G} + \text{H}) \rightsquigarrow Q \\
  & = \forall\ x\ . (\text{G} + \text{H})\ x \rightarrow Q\ x \\
  & = \forall\ x\ . (\text{G}\ x + \text{H}\ x) \rightarrow Q\ x \\
  & = (\forall\ x\ . \text{G}\ x \rightarrow Q\ x) \times (\forall\ x\ . \text{H}\ x \rightarrow Q\ x) \\
  & = (\text{G} \rightsquigarrow Q) \times (\text{H} \rightsquigarrow Q)
\end{align}$$

As we previously saw when introducing (\\(\text{\_} \mathrel{\hat{}} \text{\_}\\)), we ended up with a product in the input.
This time we can run the same scenaro backwards to end up with (\\(\text{\_} \mathrel{\hat{}} \text{\_}\\)) for the output.

$$\begin{align}
  & = (\text{F} \times \text{G}) \rightsquigarrow Q \\
  & = \text{F} \rightsquigarrow (Q \mathrel{\hat{}} \text{G}) \\
  & = \text{G} \rightsquigarrow (Q \mathrel{\hat{}} \text{F}) \\
  & = \text{Proxy} \rightsquigarrow (Q \mathrel{\hat{}} (\text{F} \times \text{G}))
\end{align}$$

Similarly to using Ran on the output to get a composition on the input, we can
use Lan on the input to get a composition on the output:

$$\begin{align}
  & = (\text{G} \backslash \text{F}) \rightsquigarrow Q \\
  & = \forall\ x\ . (\text{G} \backslash \text{F})\ x \rightarrow Q\ x \\
  & = \forall\ x\ . (\exists\ y\ . (\text{F}\ y,\ \text{G}\ y \rightarrow x)) \rightarrow Q\ x \\
  & = \forall\ x\ y\ . \text{F}\ y \rightarrow (\text{G}\ y \rightarrow x) \rightarrow Q\ x \\
  & = \forall\ y\ . \text{F}\ y \rightarrow \forall\ x\ . (\text{G}\ y \rightarrow x) \rightarrow Q\ x \\
  & = \forall\ y\ . \text{F}\ y \rightarrow Q\ (\text{G}\ y) \\
  & = \forall\ y\ . \text{F}\ y \rightarrow (Q \circ \text{G})\ y \\
  & = \text{F} \rightsquigarrow (Q \circ \text{G})
\end{align}$$

