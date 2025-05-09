import LinearAlgebra: qr, ldiv!
using Random
# this implements the 1D p-laplacian (p = 4)
#      F(u) = ∑_{i=1}^{N} h (W(u_i') - ∑_{i=1}^{N-1} h u_i
#  where u_i' = (u_i - u_{i-1})/h
#  plap: implements the functional without boundary condition
#  preconditioner is a discrete laplacian, which defines a metric
#     equivalent (in the limit h → 0) to that induced by the hessian, but
#     does not approximate the hessian explicitly.
@testset "Preconditioning" begin
    plap(U; n = length(U)) = (n - 1) * sum((0.1 .+ diff(U) .^ 2) .^ 2) - sum(U) / (n - 1)
    plap1(U; n = length(U), dU = diff(U), dW = 4 .* (0.1 .+ dU .^ 2) .* dU) =
        (n - 1) .* ([0.0; dW] .- [dW; 0.0]) .- ones(n) / (n - 1)
    precond(x::Vector) = precond(length(x))
    precond(n::Number) =
        spdiagm(-1 => -ones(n - 1), 0 => 2 * ones(n), 1 => -ones(n - 1)) * (n + 1)
    f(X) = plap([0; X; 0])
    g!(G, X) = copyto!(G, (plap1([0; X; 0]))[2:end-1])

    GRTOL = 1e-6

    debug_printing && println("Test a basic preconditioning example")
    for N in (10, 50, 250)
        debug_printing && println("N = ", N)
        initial_x = zeros(N)
        Plap = precond(initial_x)
        Hess = ForwardDiff.hessian(f, initial_x)
        ID = nothing
        for optimizer in (GradientDescent, ConjugateGradient, LBFGS)
            for (P, Prep, wwo) in zip(
                (ID, Plap, Hess, Hess),
                (
                    Returns(nothing),
                    Returns(nothing),
                    Returns(nothing),
                    (P, x) -> ForwardDiff.hessian!(P, f, x),
                ),
                (" WITHOUT", " WITH", " WITH Hessian", " WITH Hessian Prep"),
            )
                results = Optim.optimize(
                    f,
                    g!,
                    copy(initial_x),
                    optimizer(P = P, precondprep = Prep),
                    Optim.Options(
                        g_tol = GRTOL,
                        allow_f_increases = true,
                        iterations = 250000,
                    ),
                )
                debug_printing && println(
                    optimizer,
                    wwo,
                    " preconditioning : g_calls = ",
                    Optim.g_calls(results),
                    ", f_calls = ",
                    Optim.f_calls(results),
                    ", iterations = ",
                    Optim.iterations(results),
                )
                if (optimizer == GradientDescent) && (N > 15) && (P == ID)
                    debug_printing &&
                        println("    (gradient descent is not expected to converge)")
                else
                    @test Optim.converged(results)
                end
            end
        end
    end

    @testset "no ☠️ #900" begin
        x, y, A = randn(10), randn(10), qr(randn(10, 10) + 4I)
        ldiv!(x, A, y)
        @test_throws MethodError ldiv!(x, nothing, y)
    end

    @testset "custom precoditioner in CG, GD" for method in (
        ConjugateGradient,
        GradientDescent,
        LBFGS,
    )
        Random.seed!(343)
        x, A = randn(2), Diagonal([1.0, 1.0])
        rosenbrock(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2

        results1 = Optim.optimize(rosenbrock, x, method(P = A), Optim.Options())
        results2 = Optim.optimize(rosenbrock, x, method(), Optim.Options())
        # can differ because of a matrix multiplication and addition in the non-nothing case
        # but should be *very* small
        @test results1.minimum ≈ results2.minimum atol = 1e-16
    end
end
