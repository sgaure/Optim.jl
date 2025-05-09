@testset "Particle Swarm" begin
    # TODO: Run on MultivariateProblems.UnconstrainedProblems?
    Random.seed!(100)

    function f_s(x::AbstractVector)
        (x[1] - 5.0)^4
    end

    function rosenbrock_s(x::AbstractVector)
        (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
    end

    function rosenbrock_s(val::AbstractVector, X::AbstractMatrix)
        for i in axes(X, 2)
            val[i] = rosenbrock_s(X[:, i])
        end
    end


    initial_x = [0.0]
    upper = [100.0]
    lower = [-100.0]
    n_particles = 4
    options = Optim.Options(iterations = 100)
    res = Optim.optimize(f_s, initial_x, ParticleSwarm(lower, upper, n_particles), options)
    @test norm(Optim.minimizer(res) - [5.0]) < 0.1

    initial_x = [0.0, 0.0]
    lower = [-20.0, -20.0]
    upper = [20.0, 20.0]
    n_particles = 5
    options = Optim.Options(iterations = 300)
    res = Optim.optimize(
        rosenbrock_s,
        initial_x,
        ParticleSwarm(lower, upper, n_particles),
        options,
    )
    @test norm(Optim.minimizer(res) - [1.0, 1.0]) < 0.1
    options = Optim.Options(
        iterations = 10,
        show_trace = true,
        extended_trace = true,
        store_trace = true,
    )
    res = Optim.optimize(
        rosenbrock_s,
        initial_x,
        ParticleSwarm(lower, upper, n_particles),
        options,
    )
    @test summary(res) == "Particle Swarm"
    res = Optim.optimize(
        rosenbrock_s,
        initial_x,
        ParticleSwarm(n_particles = n_particles),
        options,
    )
    @test summary(res) == "Particle Swarm"
    res = Optim.optimize(rosenbrock_s, initial_x, ParticleSwarm(n_particles = n_particles, batched=true), options)
    @test summary(res) == "Particle Swarm"
end
