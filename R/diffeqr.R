#' Setup diffeqr
#'
#' This function initializes Julia and the DifferentialEquations.jl package.
#' The first time will be long since it includes precompilation.
#'
#' @param ... Parameters are passed down to JuliaCall::julia_setup
#'
#' @export
diffeq_setup <- function (...){
  julia <- JuliaCall::julia_setup(...)
  JuliaCall::julia_install_package_if_needed("DifferentialEquations")
  JuliaCall::julia_library("DifferentialEquations")
}

#' Solve Ordinary Differential Equations (ODE)
#'
#' Solves an ODE with u'=f(u,p,t), for u(0)=u0 over the tspan
#' @param f the derivative function.
#' @param u0 the initial condition. Can be a number or (arbitrary dimension) array.
#' @param tspan the timespan to solve over. Should be a list of two values: (initial time, end time).
#' @param p the parameters. Defaults to no parameters. Can be a number or an array.
#' @param alg the algorithm used to solve the differential equation. Defaults to an adaptive choice.
#'        Algorithm choices are done through a string which matches the DifferentialEquations.jl form.
#' @param reltol the relative tolerance of the ODE solver. Defaults to 1e-3.
#' @param abstol the absolute tolerance of the ODE solver. Defaults to 1e-6
#' @param saveat the time points to save values at. Should be an array of times. Defaults to automatic.
#'
#' @return sol. Has the sol$t for the time points and sol$u for the values.
#'
#' @export
ode.solve <- function(f,u0,tspan,p=NULL,alg="nothing",reltol=1e-3,abstol=1e-6,saveat=NULL){
  if (is.character(f)){
    fname = f
  } else {
    JuliaCall::julia_assign("___f", f)
    fname = "___f"
  }
  JuliaCall::julia_assign("u0", u0)
  tspan_tup = tspan
  class(tspan_tup) <- "JuliaTuple"
  JuliaCall::julia_assign("tspan", tspan_tup)
  if (is.null(p)){
    p_str = "nothing"
  } else {
    p_str = "p"
    JuliaCall::julia_assign("p", p)
  }
  if (is.null(saveat)){
    saveat_str = "eltype(prob.tspan)[]"
  } else {
    saveat_str = "saveat"
    JuliaCall::julia_assign("saveat", saveat)
  }
  jleval = stringr::str_interp("prob = ODEProblem(${fname},u0,tspan,${p_str})")
  JuliaCall::julia_eval(jleval)
  jleval = stringr::str_interp("sol = solve(prob,${alg},reltol=${reltol},abstol=${abstol}, saveat=${saveat_str}); nothing")
  JuliaCall::julia_eval(jleval)
  u = JuliaCall::julia_eval("typeof(u0)<:Number ? Array(sol) : sol'")
  t = JuliaCall::julia_eval("sol.t")
  list(u=u,t=t)
}

#' Solve Stochastic Differential Equations (SDE)
#'
#' Solves an SDE with du=f(u,p,t)dt + g(u,p,t)dW_t, for u(0)=u0 over the tspan
#' @param f the drift function.
#' @param g the diffusion function.
#' @param u0 the initial condition. Can be a number or (arbitrary dimension) array.
#' @param tspan the timespan to solve over. Should be a list of two values: (initial time, end time).
#' @param p the parameters. Defaults to no parameters. Can be a number or an array.
#' @param alg the algorithm used to solve the differential equation. Defaults to an adaptive choice.
#'        Algorithm choices are done through a string which matches the DifferentialEquations.jl form.
#' @param reltol the relative tolerance of the ODE solver. Defaults to 1e-3.
#' @param abstol the absolute tolerance of the ODE solver. Defaults to 1e-6
#' @param saveat the time points to save values at. Should be an array of times. Defaults to automatic.
#' @param noise.dims list of the dimensions for the noise rate term. Defaults to NULL which gives diagonal noise.
#'
#' @return sol. Has the sol$t for the time points and sol$u for the values.
#'
#' @export
sde.solve <- function(f,g,u0,tspan,p=NULL,alg="nothing",noise.dims=NULL,reltol=1e-2,abstol=1e-2,saveat=NULL){
  if (is.character(f)){
    fname = f
  } else {
    JuliaCall::julia_assign("___f", f)
    fname = "___f"
  }
  if (is.character(g)){
    gname = g
  } else {
    JuliaCall::julia_assign("___g", g)
    gname = "___g"
  }
  JuliaCall::julia_assign("u0", u0)
  tspan_tup = tspan
  class(tspan_tup) <- "JuliaTuple"
  JuliaCall::julia_assign("tspan", tspan_tup)
  if (is.null(p)){
    p_str = "nothing"
  } else {
    p_str = "p"
    JuliaCall::julia_assign("p", p)
  }
  if (is.null(saveat)){
    saveat_str = "eltype(prob.tspan)[]"
  } else {
    saveat_str = "saveat"
    JuliaCall::julia_assign("saveat", saveat)
  }
  if (is.null(noise.dims)) {
    nrp_str = "nothing"
  } else {
    nrp_str = stringr::str_interp("zeros(${noise.dims[1]},${noise.dims[2]})")
  }
  jleval = stringr::str_interp("prob = SDEProblem(${fname},${gname},u0,tspan,${p_str},noise_rate_prototype=${nrp_str})")
  JuliaCall::julia_eval(jleval)
  jleval = stringr::str_interp("sol = solve(prob,${alg},reltol=${reltol},abstol=${abstol}, saveat=${saveat_str}); nothing")
  JuliaCall::julia_eval(jleval)
  u = JuliaCall::julia_eval("typeof(u0)<:Number ? Array(sol) : sol'")
  t = JuliaCall::julia_eval("sol.t")
  list(u=u,t=t)
}

#' Solve Differential-Algebraic Equations (DAE)
#'
#' Solves a DAE with f(du,u,p,t)=0 for u(0)=u0 over the tspan
#' @param f the implicit ODE function.
#' @param du0 the initial derivative. Can be a number or (arbitrary dimension) array.
#' @param u0 the initial condition. Can be a number or (arbitrary dimension) array.
#' @param tspan the timespan to solve over. Should be a list of two values: (initial time, end time).
#' @param p the parameters. Defaults to no parameters. Can be a number or an array.
#' @param alg the algorithm used to solve the differential equation. Defaults to an adaptive choice.
#'        Algorithm choices are done through a string which matches the DifferentialEquations.jl form.
#' @param differential_vars boolean array declaring which variables are differential. All falses correspond to
#'        purely algebraic variables.
#' @param reltol the relative tolerance of the ODE solver. Defaults to 1e-3.
#' @param abstol the absolute tolerance of the ODE solver. Defaults to 1e-6
#' @param saveat the time points to save values at. Should be an array of times. Defaults to automatic.
#'
#' @return sol. Has the sol$t for the time points and sol$u for the values.
#'
#' @export
dae.solve <- function(f,du0,u0,tspan,p=NULL,alg="nothing",reltol=1e-3,abstol=1e-6,saveat=NULL,differential_vars=NULL){
  if (is.character(f)){
    fname = f
  } else {
    JuliaCall::julia_assign("___f", f)
    fname = "___f"
  }
  JuliaCall::julia_assign("u0", u0)
  JuliaCall::julia_assign("du0", du0)
  tspan_tup = tspan
  class(tspan_tup) <- "JuliaTuple"
  JuliaCall::julia_assign("tspan", tspan_tup)
  if (is.null(p)){
    p_str = "nothing"
  } else {
    p_str = "p"
    JuliaCall::julia_assign("p", p)
  }
  if (is.null(saveat)){
    saveat_str = "eltype(prob.tspan)[]"
  } else {
    saveat_str = "saveat"
    JuliaCall::julia_assign("saveat", saveat)
  }
  if (is.null(differential_vars)){
    diffvar_str = "nothing"
  } else {
    diffvar_str = "diffvars"
    JuliaCall::julia_assign("diffvars",differential_vars)
  }
  jleval = stringr::str_interp("prob = DAEProblem(${fname},du0,u0,tspan,${p_str},differential_vars=${diffvar_str})")
  JuliaCall::julia_eval(jleval)
  jleval = stringr::str_interp("sol = solve(prob,${alg},reltol=${reltol},abstol=${abstol}, saveat=${saveat_str}); nothing")
  JuliaCall::julia_eval(jleval)
  u = JuliaCall::julia_eval("typeof(u0)<:Number ? Array(sol) : sol'")
  t = JuliaCall::julia_eval("sol.t")
  list(u=u,t=t)
}

#' Solve Delay Differential Equations (DDE)
#'
#' Solves a DDE with f(u,p,t)=0 for u(0)=u0 over the tspan
#' @param f the implicit ODE function.
#' @param u0 the initial condition. Can be a number or (arbitrary dimension) array.
#' @param h is the history function (p,t) which gives values of the solution before the initial time point.
#' @param tspan the timespan to solve over. Should be a list of two values: (initial time, end time).
#' @param p the parameters. Defaults to no parameters. Can be a number or an array.
#' @param alg the algorithm used to solve the differential equation. Defaults to an adaptive choice.
#'        Algorithm choices are done through a string which matches the DifferentialEquations.jl form.
#' @param reltol the relative tolerance of the ODE solver. Defaults to 1e-3.
#' @param abstol the absolute tolerance of the ODE solver. Defaults to 1e-6
#' @param saveat the time points to save values at. Should be an array of times. Defaults to automatic.
#' @param constant_lags a vector of floats for the constant-time lags. Defaults to NULL.
#'
#' @return sol. Has the sol$t for the time points and sol$u for the values.
#'
#' @export
dde.solve <- function(f,u0,h,tspan,p=NULL,alg="nothing",reltol=1e-3,abstol=1e-6,saveat=NULL,constant_lags=NULL){
  if (is.character(f)){
    fname = f
  } else {
    JuliaCall::julia_assign("___f", f)
    fname = "___f"
  }
  if (is.character(h)){
    hname = h
  } else {
    JuliaCall::julia_assign("___h", h)
    hname = "___h"
  }

  JuliaCall::julia_assign("u0", u0)
  tspan_tup = tspan
  class(tspan_tup) <- "JuliaTuple"
  JuliaCall::julia_assign("tspan", tspan_tup)
  if (is.null(p)){
    p_str = "nothing"
  } else {
    p_str = "p"
    JuliaCall::julia_assign("p", p)
  }
  if (is.null(saveat)){
    saveat_str = "eltype(prob.tspan)[]"
  } else {
    saveat_str = "saveat"
    JuliaCall::julia_assign("saveat", saveat)
  }
  if (is.null(constant_lags)){
    cl_str = "nothing"
  } else {
    cl_str = "cl"
    JuliaCall::julia_assign("cl",constant_lags)
  }
  jleval = stringr::str_interp("prob = DDEProblem(${fname},u0,${hname},tspan,${p_str},constant_lags=${cl_str})")
  JuliaCall::julia_eval(jleval)
  jleval = stringr::str_interp("sol = solve(prob,${alg},reltol=${reltol},abstol=${abstol}, saveat=${saveat_str}); nothing")
  JuliaCall::julia_eval(jleval)
  u = JuliaCall::julia_eval("typeof(u0)<:Number ? Array(sol) : sol'")
  t = JuliaCall::julia_eval("sol.t")
  list(u=u,t=t)
}
