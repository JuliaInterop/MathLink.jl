# MathLink.jl

[![CI](https://github.com/JuliaInterop/MathLink.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaInterop/MathLink.jl/actions/workflows/CI.yml)

This package provides access to Mathematica/Wolfram Engine via the MathLink library, now renamed to [Wolfram Symbolic Transfer Protocol (WSTP)](https://www.wolfram.com/wstp/). 

## Installation

The package requires an installation of either [Mathematica](http://www.wolfram.com/mathematica/) or the free [Wolfram Engine](https://www.wolfram.com/engine/). It will attempt to find the installation at build time; if this fails, please see the [installation troubleshoot](#installation-troubleshoot) below.
 
 
## Usage

The main interface consists of the `W""` string macro for specifying symbols. These are call-overloaded for building more complicated expressions. 

```julia
julia> using MathLink

julia> W"Sin"
W"Sin"

julia> sin1 = W"Sin"(1.0)
W`Sin[1.0]`

julia> sinx = W"Sin"(W"x")
W`Sin[x]`
```

To parse an expression in the Wolfram Language, you can use the `W` cmd macro (note the backticks):
```julia
julia> W`Sin[1]`
W`Sin[1]`
```

`weval` evaluates an expression:
```julia
julia> weval(sin1)
0.8414709848078965

julia> weval(sinx)
W`Sin[x]`

julia> weval(W"Integrate"(sinx, (W"x", 0, 1)))
W`Plus[1, Times[-1, Cos[1]]]`
```

Keyword arguments can be used to pass local variables
```julia
julia> weval(sinx; x=2.0)
0.9092974268256817
```

## The algebraic operators

MathLink also overloads the `+`, `-`, `*`, `/`  operations.

```julia
julia> using MathLink

julia> W"a"+W"b"
W`Plus[a, b]`

julia> W"a"+W"a"
W`Plus[a, a]`

julia> W"a"-W"a"
W`Plus[a, Minus[a]]`
```

One can toggle automatic use of `weval`  on-and-off using `set_GreedyEval(x::Bool)`

```julia
julia> set_GreedyEval(true);

julia> W"a"+W"b"
W`Plus[a, b]`

julia> W"a"+W"a"
W`Times[2, a]`

julia> W"a"-W"a"
0
```


## Fractions and Complex numbers
 
The package also contains extensions to handle fractions.

```julia
julia> weval(1//2)
W`Rational[1, 2]`

julia> (4//5)*W"a"
W`Times[Rational[4, 5], a]`

julia> W"a"/(4//5)
W`Times[Rational[5, 4], a]`
```

and complex numbers

```julia
julia> im*W"a"
W`Times[Complex[0, 1], a]`

julia> im*(im*W"c")
W`Times[-1, c]`
```


## Matrix Multiplication
Since the arithmetic operators are overloaded, operations such as matrix multiplication are also possible by default.

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




## W2JuliaStruct - Conversion to Julia structures
`W2JuliaStruct` is designed primarily to convert wolfram structures to Julia structures. This includes conversions of Mathematica lists to Julia vectors and Mathematica associations to Julia dictionaries.

Some examples or tests that will evaluate to true:

```julia
using Test
@test W2JuliaStruct(W`{1,2,3}`) == [1,2,3]
@test W2JuliaStruct([1,2,3]) == [1,2,3]
@test W2JuliaStruct(W`{1,2,3}`) == [1,2,3]
@test W2JuliaStruct(W`{1,a,{1,2}}`) == [1,W"a",[1,2]]
@test W2JuliaStruct([.1,W`{1,a,3}`]) == [.1,[1,W"a",3]]

@test W2JuliaStruct(Dict( 1 => "A" , "B" => 2)) ==Dict( 1 => "A" , "B" => 2)

@test W2JuliaStruct(W`Association["A" -> "B", "C" -> "D"]`) == Dict( "A" => "B" , "C" => "D")

@test W2JuliaStruct(W`Association["A" -> {1,a,3}, "B" -> "C"]`) == Dict( "A" => [1,W"a",3] , "B" => "C")
```

`W2JuliaStruct` does not convert expressions to Julia functions, as not all functions will be able to evaluate when WSymbols are present.


## LateX printing in JuPyter Notebooks
Printing in Jupyter notebooks is, by default, done in latex.
This can be turned off with the command `MathLink.set_texOutput(false)`

## Escaping dollars for Mathematica
The `$` sign has a special meaning in Julia, but it does not in Mathematica. We can send dollar signs to Mathematica that same way we add them to normal strings. Below are a few examples of how it works: 

    using Test
    x = exp(1)
    @test W`$x` == x
    @test W`\$` == W"$"
    @test W`\$x` == W"$x"
    @test W`$x +\$` == x+W"$"
    @test W`"\$"` == "\$"
    @test W`"a"` == "a"
    @test W`{a -> b}` == W"List"(W"Rule"(W"a",W"b"))
    @test W`{"a" -> "b"}` == W"List"(W"Rule"("a","b"))
    @test W`"a" -> "b"` == W"Rule"("a","b")
    @test W`a -> b` == W"Rule"(W"a",W"b")
    @test W`"b(\$)a"` == "b(\$)a"
    @test W`"b\\\$"` == "b\\\$"
    @test W`"b\$"` == "b\$"
    @test W`"\$a"` == "\$a"
    @test W`"\$" -> "b"` == W"Rule"("\$","b")
    @test W`{"\$" -> "b"}` == W"List"(W"Rule"("\$","b"))
    @test W`{"a" -> "\$"}` == W"List"(W"Rule"("a","\$"))
    @test W`{a -> "\$"}` == W"List"(W"Rule"(W"a","\$"))



## Installation Troubleshoot
The package requires an installation of either [Mathematica](http://www.wolfram.com/mathematica/) or the free [Wolfram Engine](https://www.wolfram.com/engine/). It will attempt to find the installation at build time; if this fails, you will need to set the following [environment variables](https://docs.julialang.org/en/v1/manual/environment-variables/):
- `JULIA_MATHKERNEL`: the path of the MathKernel executable
- `JULIA_MATHLINK`: the path of the MathLink dynamic library named
  - `libML64i4.so`/ `libML32i4.so` on Linux
  - `ml64i4.dll`/`ml32i4.dll`/`libML64.dll`/ `libML32.dll` on Windows

After setting, you may need to manually build the package
```julia
(@v1.X) pkg> build MathLink
```
 
A separate workaround is to directly edit the deps/deps.jl file, which should be located (on Linux) at `~/.julia/packages/MathLink/<version dependent>/deps/deps.jl`
 
The contents of `deps.jl` could for instance, read
```julia
const mlib = "/usr/local/Wolfram/Mathematica/11.3/SystemFiles/Links/MathLink/DeveloperKit/Linux-x86-64/CompilerAdditions/libML64i4"
const mker = "WolframKernel"
```
After creating the file `deps.jl` try loading MathLink the usual way
```julia
(@v1.X) pkg> using MathLink
```
If you do not have a Mathematica installation at all, the above trick still works, but then you must leave the path blank 
```julia
const mlib = ""
const mker = "WolframKernel"
```
Loading `MathLink` then proclaims
```julia
julia> using MathLink
[ Info: Precompiling MathLink [18c93696-a329-5786-9845-8443133fa0b4]
[ Info: Pretending fake installation works
```

## Relation to other packages
The MathLink package is a free standing package with verry few dependencies. However, it can be made to work with e.g. the [Symbolics](https://github.com/JuliaSymbolics/Symbolics.jl) package with the help of the package [SymbolicsMathLink](https://github.com/eswagel/SymbolicsMathLink.jl).

For documenation of these for packages, see their respective project pages.


## Notes

- Mathematica, Wolfram, MathLink are all trademarks of Wolfram Research.
