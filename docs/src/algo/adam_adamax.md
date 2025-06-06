# Adam and AdaMax
This page contains information about Adam and AdaMax. Notice, that these algorithms do not use line search algorithms, so some tuning of `alpha` may be necessary to obtain sufficiently fast convergence on your specific problem.
## Constructors
```julia
Adam(;  alpha=0.0001,
        beta_mean=0.9,
        beta_var=0.999,
        epsilon=1e-8)
```

where `alpha` is the step length or learning parameter. `beta_mean` and `beta_var` are exponential decay parameters for the first and second moments estimates. Setting these closer to 0 will cause past iterates to matter less for the current steps and setting them closer to 1 means emphasizing past iterates more. `epsilon` should rarely be changed, and just exists to avoid a division by 0.


```julia
AdaMax(; alpha=0.002,
         beta_mean=0.9,
         beta_var=0.999,
         epsilon=1e-8)
```
where `alpha` is the step length or learning parameter. `beta_mean` and `beta_var` are exponential decay parameters for the first and second moments estimates. Setting these closer to 0 will cause past iterates to matter less for the current steps and setting them closer to 1 means emphasizing past iterates more.

## References

```@bibliography
kingma2017
```
