# MathLink.jl

This package provides access to Mathematica/Wolfram Engine via the *MathLink* library (now renamed to WSTP).

## Installation

The package requires a [Mathematica](http://www.wolfram.com/mathematica/) or [Wolfram Engine](https://www.wolfram.com/engine/) installation. It will attempt to find the installation at build time; if this fails, you will need to set the following environment variables:
- `JULIA_MATHLINK`: the path of the MathLink dynamic library
- `JULIA_MATHKERNEL`: the path of the MathKernel executable

## Usage

The main interface consists of the `W""` string macro for specifying symbols. These are call-overloaded for building more complicated expressions 

```
julia> using MathLink

julia> W"Sin"
W"Sin"

julia> sin1 = W"Sin"(1.0)
W"Sin(1.0)"

julia> sinx = W"Sin"(W"x")
W"Sin"(W"x")
```

`weval` evaluates an expression:
```
julia> weval(sin1)
0.8414709848078965

julia> weval(sinx)
W"Sin"(W"x")

julia> weval(W"Integrate"(sinx, (W"x", 0, 1)))
W"Plus"(1, W"Times"(-1, W"Cos"(1)))
```
