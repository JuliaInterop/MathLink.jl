# MathLink.jl

[![Build Status](https://travis-ci.org/JuliaInterop/MathLink.jl.svg?branch=master)](https://travis-ci.org/JuliaInterop/MathLink.jl)

This package provides access to Mathematica/Wolfram Engine via the MathLink library, now renamed to [Wolfram Symbolic Transfer Protocol (WSTP)](https://www.wolfram.com/wstp/). 

## Installation

The package requires an installation of either [Mathematica](http://www.wolfram.com/mathematica/) or the free [Wolfram Engine](https://www.wolfram.com/engine/). It will attempt to find the installation at build time; if this fails, you will need to set the following environment variables:
- `JULIA_MATHKERNEL`: the path of the MathKernel executable
- `JULIA_MATHLINK`: the path of the MathLink dynamic library named
  - `libML64i4.so`/ `libML32i4.so` on Linux
  - `libML64.dll`/ `libML32.dll` on Windows
  - `mathlink` on macOS (if the free Wolfram Engine is used you need to set `ENV["JULIA_MATHLINK"] = "/Applications/Wolfram Engine.app/Contents/Resources/Wolfram Player.app/Contents/SystemFiles/Links/MathLink/DeveloperKit/MacOSX-x86-64/CompilerAdditions/mathlink.framework/mathlink"`)
  
## Usage

The main interface consists of the `W""` string macro for specifying symbols. These are call-overloaded for building more complicated expressions 

```julia
julia> using MathLink

julia> W"Sin"
W"Sin"

julia> sin1 = W"Sin"(1.0)
W"Sin(1.0)"

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

## Notes

- Mathematica, Wolfram, MathLink are all trademarks of Wolfram Research.
