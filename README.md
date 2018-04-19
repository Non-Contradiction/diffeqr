# diffeqr

[![Build Status](https://travis-ci.org/JuliaDiffEq/diffeqr.svg?branch=master)](https://travis-ci.org/JuliaDiffEq/diffeqr)

diffeqr is a package for solving differential equations in R. It utilizes 
[DifferentialEquations.jl](http://docs.juliadiffeq.org/latest/) for its core routines 
to give high performance solving of ordinary differential equations (ODEs),
stochastic differential equations (SDEs), delay differential equations (DDEs), and
differential-algebraic equations (DAEs) directly in R.

## Installation

diffeqr is currently not registered into CRAN. Thus to use this package, use the following command:

```R
devtools::install_github('JuliaDiffEq/diffeqr', build_vignettes=T)
```

## Usage

diffeqr does not provide the full functionality of DifferentialEquations.jl. Instead, it supplies simplified
direct solving routines with an R interface. The most basic function is:

```R
ode.solve(f,u0,tspan,[p,abstol,reltol,saveat])
```

which solves the ODE `u' = f(u,p,t)` where `u(0)=u0` over the timespan `tspan`. 
The common interface arguments are documented 
[at the DifferentialEquations.jl page](http://docs.juliadiffeq.org/latest/basics/common_solver_opts.html).
Notice that not all options are allowed, but the most common arguments are supported.

## ODE Examples

### 1D Linear ODEs

Let's solve the linear ODE `u'=1.01u`. Start by loading the library:

```R
library(diffeqr)
```

Then define our derivative function `f(u,p,t)`. 

```R
f <- function(u,p,t) {
  return(1.01*u)
}
```

Then we give it an initial condition and a time span to solve over:

```R
u0 = 1/2
tspan <- list(0.0,1.0)
```

With those pieces we call `ode.solve` to solve the ODE:

```R
sol = ode.solve(f,u0,tspan)
```

This gives back a solution object for which `sol$t` are the time points
and `sol$u` are the values. We can check it by plotting the solution:

```R 
plot(sol$t,sol$u,"l")
```

![linear_ode](https://user-images.githubusercontent.com/1814174/39011970-e04f1fe8-43c7-11e8-8da3-848362691783.png)

### Systems of ODEs

Now let's solve the Lorenz equations. In this case, our initial condition is a vector and our derivative functions
takes in the vector to return a vector (note: arbitrary dimensional arrays are allowed). We would define this as:

```R
f <- function(u,p,t) {
  du1 = p[1]*(u[2]-u[1])
  du2 = u[1]*(p[2]-u[3]) - u[2]
  du3 = u[1]*u[2] - p[3]*u[3]
  return(c(du1,du2,du3))
}
```

Here we utilized the parameter array `p`. Thus we use `ode.solve` like before, but also pass in parameters this time:

```R
u0 = c(1.0,0.0,0.0)
tspan <- list(0.0,100.0)
p = c(10.0,28.0,8/3)
sol = ode.solve(f,u0,tspan,p=p)
```

The returned solution is like before. It is convenient to turn it into a data.frame:

```R
udf = as.data.frame(sol$u)
```

Now we can use `matplot` to plot the timeseries together:

```R
matplot(sol$t,udf,"l",col=1:3)
```

![timeseries](https://user-images.githubusercontent.com/1814174/39012314-ef7a8fe2-43c8-11e8-9dde-1a8b87d3cfa4.png)

Now we can use the Plotly package to draw a phase plot:

```R
library(plotly)
plot_ly(udf, x = ~V1, y = ~V2, z = ~V3, type = 'scatter3d', mode = 'lines')
```

![plotly_plot](https://user-images.githubusercontent.com/1814174/39012384-27ee7262-43c9-11e8-84d2-1edf937288ae.png)

Plotly is much prettier!
