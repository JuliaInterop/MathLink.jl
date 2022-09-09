# MathLink.jl

[![Build Status](https://travis-ci.org/JuliaInterop/MathLink.jl.svg?branch=master)](https://travis-ci.org/JuliaInterop/MathLink.jl)

This package provides access to Mathematica/Wolfram Engine via the MathLink library, now renamed to [Wolfram Symbolic Transfer Protocol (WSTP)](https://www.wolfram.com/wstp/). 

## Installation

The package requires an installation of either [Mathematica](http://www.wolfram.com/mathematica/) or the free [Wolfram Engine](https://www.wolfram.com/engine/). It will attempt to find the installation at build time; if this fails, you will need to set the following environment variables:
- `JULIA_MATHKERNEL`: the path of the MathKernel executable
- `JULIA_MATHLINK`: the path of the MathLink dynamic library named
  - `libML64i4.so`/ `libML32i4.so` on Linux
  - `ml64i4.dll`/`ml32i4.dll`/`libML64.dll`/ `libML32.dll` on Windows

After setting you may need to manually build the package
```julia
(@v1.X) pkg> build MathLink
```
  
## Usage

The main interface consists of the `W""` string macro for specifying symbols. These are call-overloaded for building more complicated expressions 

```julia
julia> using MathLink

julia> W"Sin"
W"Sin"

julia> sin1 = W"Sin"(1.0)
W"Sin"(1.0)

julia> sinx = W"Sin"(W"x")
W"Sin"(W"x")
```

To parse an expression in the Wolfram Language, you can use the `W` cmd macro (note the backticks):
```julia
julia> W`Sin[1]`
W"Sin"(1)
```

`weval` evaluates an expression:
```julia
julia> weval(sin1)
0.8414709848078965

julia> weval(sinx)
W"Sin"(W"x")

julia> weval(W"Integrate"(sinx, (W"x", 0, 1)))
W"Plus"(1, W"Times"(-1, W"Cos"(1)))
```

Keyword arguments can be used to pass local variables
```julia
julia> weval(sinx; x=2.0)
0.9092974268256817
```

## The algebraic operators

MathLink also overloads the `+`, `-`, `*`, `/`  operations

```julia
julia> using MathLink

julia> W"a"+W"b"
W"Plus"(W"a",W"b")

julia> W"a"+W"a"
W"Plus"(W"a",W"a")

julia> W"a"-W"a"
W"Plus"(W"a",W"Minus"(W"a"))
```

One can toggle automatic use of `weval`  on-and-off using `set_GreedyEval(x::Bool)`

```julia
julia>set_GreedyEval(true)
julia> W"a"+W"b"
W"Plus"(W"a",W"b")

julia> W"a"+W"a"
W"Times"(2,W"a")

julia> W"a"-W"a"
0
```


## Fractions and Complex numbers
 
The package also contains extentions to handle fractions

```julia
julia> weval(1//2)
W"Rational"(1, 2)

julia> (4//5)*W"a"
W"Times"(W"Rational"(4, 5), W"a")

julia> W"a"/(4//5)
W"Times"(W"Rational"(5, 4), W"a")
```

and complex numbers

```julia
julia> im*W"a"
W"Times"(W"Complex"(0, 1), W"a")

julia> im*(im*W"c")
W"Times"(-1, W"c")
```


## Matrix Multiplication
Since the arithematic operators are overloaded, operations such as matrix multiplication are also possible by default

```julia
julia> P12 = [ 0 1 ; 1 0 ]
2×2 Matrix{Int64}:
 0  1
 1  0

julia> set_GreedyEval(true)
true

julia> P12 * [W"a" W"b" ; W`a+b` 2] == [ W"b" 2-W"b" ; W"a" W"b"]
true
```


## W2Mstr - Mathematica conversion
Sometimes one wants to be able to read the Julia MathLink expressions back into Mathematica. For that purpose, `W2Mstr` is also supplied. This implementation is currently quite defensive with parentheses, which gives a more verbose output than necessary. Here are a few examples

```julia
julia> W2Mstr(W`x`)
"x"

julia> W2Mstr(W"Sin"(W"x"))
"Sin[x]"

julia> W2Mstr(weval(W`a + c + v`))
"(a + c + v)"

julia> W2Mstr(weval(W`a^(b+c)`))
"(a^(b + c))"

julia> W2Mstr(weval(W`e+a^(b+c)`))
"((a^(b + c)) + e)"

julia> W2Mstr(W"a"+W"c"+W"v"+W"Sin"(2 +W"x" + W"Cos"(W"q")))
"(a + c + v + Sin[(2 + x + Cos[q])])"

julia> W2Mstr(im*2)
"(2*I)"

julia> W2Mstr(weval(W"Complex"(W"c",W"b")))
"(c+b*I)"

julia> W2Mstr(W"c"+im*W"b")
"(((1*I)*b) + c)"

julia> W2Mstr(W`b/(c^(a+c))`)
"(b*((c^(a + c))^-1))"
```


## LateX printing in JuPyter Notebooks
Printing in Juypter notebooks is by defaults done in latex.
This can be turned off with the command `MathLink.set_texOutput(false)`

## Notes

- Mathematica, Wolfram, MathLink are all trademarks of Wolfram Research.
