---
title: "Super Class Family Pattern"
date: 2025-08-03T20:30:00+00
---

This will be reasonably brief, but I wanted to write out a somewhat compelling
scenario to demonstrate the problem & solution.

To demonstrate the idea we will explore representing the profunctor class
hierarchy using a singular class.

Here are some of the common Profunctor classes (approximately) from the
profunctors library:

```hs
class Profunctor p where
  dimap :: (s -> a) -> (b -> t) -> p a b -> p s t

class Profunctor p => Strong p where
  second :: p a b -> p (e, a) (e, b)

class Profunctor p => Choice p where
  right :: p a b -> p (Either e a) (Either e b)

class (Strong p, Choice p) => Traversing p where
  traverse :: Traversable f => p a b -> p (f a) (f b)
```

There's an equivalent representation of these attained via Yoneda (execise for
the reader):

```hs
class Profunctor p where
  iso :: (s -> a) -> (b -> t) -> p a b -> p s t

class Profunctor p => Strong p where
  lens :: (s -> (e, a)) -> ((e, b) -> t) -> p a b -> p s t

class Profunctor p => Choice p where
  prism :: (s -> Either e a) -> (Either e b -> t) -> p a b -> p s t

class (Strong p, Choice p) => Traversing p where
  traversal :: Traversable e => (s -> e a) -> (e b -> t) -> p a b -> p s t
```

With this representation they all now have the form of `... -> p a b -> p s t`,
following suit of the original Profunctor class. The `...` here can be
structured as a data type (per class). Following from my suggestive naming of
the methods, these inputs are more commonly understood as data structure
encodings of optics, here I've called them "Data" optics:

```hs
data DataIso a b s t = DataIso (s -> a) (b -> t)
data DataLens a b s t = forall e . DataLens (s -> (e, a)) ((e, b) -> t)
data DataPrism a b s t = forall e . DataPrism (s -> Either e a) (Either e b -> t)
data DataTraversal a b s t = forall e . Traversable e => DataTraversal (s -> e a) (e b -> t)
```

These are all of kind `Type -> Type -> Type -> Type -> Type`. They can each be
thought of as the types of arrows (hom functors) in particular categories,
whose objects are pairs of types. So a `DataIso A B S T` is the type of iso
arrows from `<A, B>` to `<S, T>`. We can crudely describe such categories with
the following class (this isn't necessarily as general as one might like, but
it will suffice for this example) - I have added spacing to aid readability of
objects:

```hs
class Procategory k where
  identity ::
    k  a b  a b
  compose ::
    k  a b  s t ->
    k  x y  a b ->
    k  x y  s t

instance Procategory DataIso where ...
instance Procategory DataLens where ...
instance Procategory DataPrism where ...
instance Procategory DataTraversal where ...
```

Given that these all form categories, we can make it more obvious that each of
the profunctor classes are functors from said categories by substituting them
into the types of the previously written classes:

```hs
class Profunctor p where
  isoMap :: DataIso a b s t -> p a b -> p s t

class Profunctor p => Strong p where
  lensMap :: DataLens a b s t -> p a b -> p s t

class Profunctor p => Choice p where
  prismMap :: DataPrism a b s t -> p a b -> p s t

class (Strong p, Choice p) => Traversing p where
  traversalMap :: DataTraversal a b s t -> p a b -> p s t
```

With some straight-forward instances following the hierarchy:

```hs
instance Profunctor (DataIso x y) where isoMap = compose
instance Profunctor (DataLens x y) where isoMap = compose . isoToLens
instance Profunctor (DataPrism x y) where isoMap = compose . isoToPrism
instance Profunctor (DataTraversal x y) where isoMap = compose . isoToTraversal

instance Strong (DataLens x y) where lensMap = compose
instance Strong (DataTraversal x y) where lensMap = compose . lensToTraversal

instance Choice (DataPrism x y) where prismMap = compose
instance Choice (DataTraversal x y) where prismMap = compose . prismToTraversal

instance Traversing (DataTraversal x y) where traversalMap = compose
```

As a first attempt to capture the general form we could introduce:

```hs
class Optically k p where
  optically :: k a b s t -> p a b -> p s t
```

Such that the previous classes are special cases:

```hs
Profunctor ~= Optically DataIso
Strong ~= Optically DataLens
Choice ~= Optically DataPrism
Traversing ~= Optically DataTraversal
```

Which does indeed mostly work for specific instances, however we've lost the
hierarchy of the structure. Previously if we had an instance of `Strong` we
also had a `Profunctor` instance around to work with. Now we'd need to ask for
both `Optically DataLens` (`Strong`) and `Optically DataIso` (`Profunctor`),
when the only the former should really have had to have been explicitly
requested.

To recover this we can introduce the following type family and use it as a
super class constraint:

```hs
type Super ::
  forall i j.
  (i -> j -> Constraint) ->
  (i -> j -> Constraint)
type family Super c k p

class Super Optically k p => Optically k p where
  optically :: k a b s t -> p a b -> p s t
```

You'll need `UndecidableSuperClasses` on for this!

The super class constraints can then be explicitly written out as such:

```hs
type instance Super Optically DataIso p = ()
type instance Super Optically DataLens p = Optically DataIso p
type instance Super Optically DataPrism p = Optically DataIso p
type instance Super Optically DataTraversal p = (Optically DataLens p, Optically DataPrism p)
```

We can now re-implement the straight-forward instances, and have the compiler
continue to check that we aren't missing any ancestor instances.

```hs
instance Optically DataIso (DataIso x y) where optically = compose
instance Optically DataIso (DataLens x y) where optically = compose . isoToLens
instance Optically DataIso (DataPrism x y) where optically = compose . isoToPrism
instance Optically DataIso (DataTraversal x y) where optically = compose . isoToTraversal

instance Optically DataLens (DataLens x y) where optically = compose
instance Optically DataLens (DataTraversal x y) where optically = compose . lensToTraversal

instance Optically DataPrism (DataPrism x y) where optically = compose
instance Optically DataPrism (DataTraversal x y) where optically = compose . prismToTraversal

instance Optically DataTraversal (DataTraversal x y) where optically = compose
```

You can see a more fleshed out version of this all in [LiamGoodacre/optically](https://github.com/LiamGoodacre/optically/blob/master/src).
