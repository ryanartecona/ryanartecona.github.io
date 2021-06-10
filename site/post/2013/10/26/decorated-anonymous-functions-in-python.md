# Decorated Anonymous Functions in Python

<date>2013-10-26</date>
<tags>code, python, fp</tags>

Python functions are generally first-class objects, and that is generally all that's needed to construct higher-order functions and to engage in the style of functional programming those enable. There is, however, no language support for multiline anonymous functions, leaving a very large and unfortunate gap between `def` named functions and `lambda` expressions. I show in this article how decorators can be abused to lend anonymity to `def` function definitions.

## Functions as Values

First things first. In Python, a function is a block.

```python
def add(a, b):
    return a + b
```

When it fits on a single line, you have the option of writing a function with lambda syntax.

```python
add = lambda a, b: a + b
```

A lambda expression is especially convenient when you need to pass a simple operation to a higher-order function (a function which accepts another function as an argument).

```python
xs = [1,2,3,4,5]
squares = map(lambda x: x**2, xs)
assert squares == [1,4,9,16,25]
```

If your function argument is more complex, you’ve got to define it beforehand, and pass it by reference. This can get messy quickly.

```python
string = "Long live Guido!"
# I have a strange desire to separate
# vowels from consonants

# helper functions
is_vowel = lambda c: c.lower() in "aeiou"
is_cons = lambda c: c.lower() in "bcdfghjklmnpqrstvwxyz"

# define reducer
def reduce_letters((vs, cs), ch):
    """
    Reducer function that collects a string's vowels
    and consonants into a (vs,cs) tuple
    """
    vs = vs + ch if is_vowel(ch) else vs
    cs = cs + ch if is_cons(ch) else cs
    return (vs, cs)

# reduce with reducer, with ("","") initial argument
vowels, conss = reduce(reduce_letters, string, ("",""))

assert vowels == "oieuio" and conss == "LnglvGd"
```

In practice, the above code written in an iterative style, with local variables and a `for` loop instead of a reducing function, would be more readable and concise (more pythonic). In many cases, though, abstraction via higher-order functions and combinators lends to more modular and clearly organized code than the equivalent imperative constructs. I think this is a damn shame, because Python actually has great support for passing functions around as objects. When blocks intended as one-off operations require being defined beforehand as local functions, the distinction between functions as reusable, modular operations and lambdas as single-serving operations---a distinction that is typically very helpful in reading python code---is eroded. A significant factor keeping this functional style from being easily authored and read is syntactic support for expression-level multiline functions, which would allow the definition of operations *exactly* where they are needed (not sooner). 

In Python, a function definition is a *statement*, not an *expression*. This means the `def` keyword begins a function definition on its own line, which captures all subsequent indented lines without ambiguity. Many other dynamic languages have expression-level function definitions (JavaScripters use anonymous functions, a.k.a. ‘callbacks’, *everywhere*, and Rubyists are rightly fond of their blocks). The same would be impossible, currently, in Python, more or less because a change in indentation is the only way to signal the end of a function body (as opposed to an `end` keyword, or wrapping the body in curly braces). While they often lead to trouble, function expressions open up possibilities for very elegant and robust APIs. 

Of course, Python has no need for such toys (because [flat is better than nested](http://www.python.org/dev/peps/pep-0020/)...right?). But if it wanted, it could almost fake them using tools it does have. I will show how. 

## Decorators and Local Assignment

If you are not familiar with them, decorators are a way to modify the behavior of functions in Python. An introduction is beyond the scope of the present article, but [here’s a good decorator tutorial](http://simeonfranklin.com/blog/2012/jul/1/python-decorators-in-12-steps/#_9_decorators), and if you’re up for it you can read [the full PEP 318](http://www.python.org/dev/peps/pep-0318/). Decorators are commonly used to registers functions as handlers for certain events, to add automatic behavior for certain inputs or outputs (memoization, error handling, etc.), or to allow for easier authoring of more "advanced" functionality (`classmethod`, `property` accessors, `functools.wraps`, etc.) Fundamentally, decorators are functions that accept a single function argument, and return a new function that replaces the defined function in the defined function's own local scope. Inside, they look like this. 

```python
from functools import wraps

def log_finished(func):
    @wraps(func)
    def wrapped(*args, **kwargs):
        func(*args, **kwargs)
        print func.func_name, "finished"
    return wrapped

@log_finished
def useless():
    pass

useless() # prints "useless finished"
```

<small>
    The `@wraps` helper is unnecessary, but I include it because decorators should not be authored in practice without it. It helps keep the behavior of a decorated function from changing in hidden ways.
</small>

As it turns out, decorator functions aren’t written in a special way so much as they adhere to a certain convention that allows them to be used as decorators. Most simply, decorators are functions (callables) that accept a function as an argument and return a function as result. More concretely, decorators are simply syntactic sugar for the following form. 

```python
@decorate
def func():
    pass

# essentially desugars to:

def func(): 
    pass
func = decorate(func)
```

In english, a decorated function definition is effectively equivalent to defining a plain function, passing that function to the decorator, and overwriting the local function variable with the return value of the decorator. Note that there is nothing stopping the decorator from returning something *other* than a function to replace the original local function variable, which makes decorator syntax abusable. 

Perhaps surprisingly, the following code runs. 

```python
def call(func):
    return func()

@call
def return_two():
    return 2

assert return_two == 2
```

That is, the decorator `call` gets called as the function `return_two` is defined, with `return_two` passed as an argument, and returns the value that `return_two` returns, the int value `2`. Since `2` is returned by the decorator, the local variable `return_two`, which was originally a function object, gets immediately overwritten with `2`. In other words, whenever a decorator decorates a function, the function gets replaced by whatever the decorator returns, whether that’s a function or *any other* Python object. *Funky!*

**A word of warning**: The (ab)use of decorators for these effects are **not** consistent with their [intended use](http://www.python.org/dev/peps/pep-0318/#examples) when added to the language, **nor** with the universal expectation that decorated functions can still be used as functions. This author encourages both wild experimentation in isolation *and* responsible treatment of colleagues and library users. 

## Pseudo-anonymous Functions

Having discovered this secret about decorators, we can exploit them to implement a facility for passing an anonymous block into a function that expects one. Because a decorator only gets called with a single argument (the function to decorate), a function that supports this style of anonymous blocks will need its block to be passed in both

  1. as the last argument, and 
  2. in a separate function call, e.g. `func(arg1, arg2)(blockarg)`

To upgrade the builtin `reduce` function to behave this way, we can write a helper. 

```python
def block_reduce(xs, initial=None):
    def with_block(block):
        if initial is None:
            return reduce(block, xs)
        return reduce(block, xs, initial)
    return with_block
```

And with this, we can rewrite our previous example as the following. 

```python
@block_reduce(string, ("",""))
def vowels_conss((vs, cs), c):
    vs = vs + c if is_vowel(c) else vs
    cs = cs + c if is_cons(c) else cs
    return (vs, cs)

assert vowels_conss == ("oieuio", "LnglvGd")
```

Here, `block_reduce` first accepts the iterable and (optional) initial argument for `reduce` before accepting a function that gets applied as the reducer, and then its return value replaces `vowels_conss` in the local scope, such that the variable `vowels_conss`is no longer a function at all, but the result of the whole `block_reduce` operation. Ignore for a moment that the syntax used this way is obviously whack, and notice that `vowels_conss` *didn’t* need to be defined as a named function before it was used (its definition *is* its use), and that at *no point* in the execution of the above code does `vowels_conss` even exist in the local scope as a function that can be mistakenly referenced elsewhere. *Anonymous!*

## Curried Functions

[Function currying](http://en.wikipedia.org/wiki/Currying) is a style of defining n-ary functions in terms of unary functions. It's more common in practice in functional languages, including Haskell. A curried function that expects multiple arguments is built in terms of a series of functions which each only expect one of those arguments (unary functions), the last of which ultimately returns the result. In a language like Python, where a normal function would be invoked as `func(arg1, arg2, arg3)`, an equivalent curried function would be invoked as `curried_func(arg1)(arg2)(arg3)`. As you can imagine, writing curried functions by hand is unfortunately verbose in Python.

The important part is that, with a bit of introspection, a function can be written as usual in idiomatic Python and be extended to support (optional) curried invocation with the addition of a simple `@curried` decorator. An example implementation, as well as a slightly better introduction to optionally-curried functions can be found on [my github](https://github.com/ryanartecona/curry.py) (a more comprehensive set of functional utilities can be found in [fn.py](https://github.com/kachayev/fn.py) or [funcy](https://github.com/Suor/funcy). 

With optional curried invocation, a function expecting a block as well as non-block arguments can be written *in idiomatic python* and can be subsequently used with our pseudo-anonymous blocks.

```python
from curry import curried

# curried helpers
c_map = curried(lambda xs, fn: map(fn, xs))
c_join = curried(lambda s, xs: s.join(xs))


# --- Ex. 1 ---

words = "Long live Guido!".split()

@c_join(" ")
@c_map(words)
def exclaim_string( word ):
    return word.upper() + '!'

assert exclaim_string == "LONG! LIVE! GUIDO!!"


# --- Ex. 2 ---

@c_map(range(1,101))
def fizzbuzz( i ):
    s  = "Fizz" if i%3 is 0 else ""
    s += "Buzz" if i%5 is 0 else ""
    return s or i

# fizzbuzz == the standard FizzBuzz sequence


# --- Ex. 3 ---

import json
untrusted_json = '[["a", "b"], ["c"]]'
untrusted_obj = json.loads(untrusted_json)

# ensure untrusted_obj is a list of
# lists of single-character strings

assert type(untrusted_obj) == list
@c_map(untrusted_obj)
def valid_obj(untrusted_xs):
    assert type(xs) == list
    @c_map(untrusted_xs)
    def valid_xs(c):
        assert type(c) == unicode
        assert len(c) == 1
        return c
    return valid_xs

assert valid_obj == [["a", "b"], ["c"]]
```

Elegant? *Hell no*. Useful? Perhaps not, but I found this possibility of hacky anonymous functions in Python surprising and interesting, and I wanted to share. Mostly, I just wish multiline anonymous function definitions (as expressions) were compatible with Python’s indentation-based syntax. Tell me what you think [@ryanartecona](https://twitter.com/ryanartecona).
