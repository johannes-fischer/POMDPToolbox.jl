# a convenient way of interacting with a simulation
# maintained by @zsunberg

"""
    sim(polfunc::Function, mdp::MDP)
    sim(polfunc::Function, pomdp::POMDP)

Alternative way of running a simulation with a function specifying how to calculate the action at each timestep.

The intended usage is

    sim(mdp) do s
        # code that calculates action `a` based on `s` - this is the policy
        # you can also do other things like display something
        return a
    end

for an MDP or

    sim(pomdp) do o
        # code that does belief updates with observation `o` and calculates `a`
        # you can also do other things like display something
        return a
    end

for a POMDP.

Use the `simulator` keyword argument to specify any simulator to run the simulation. If nothing is specified for the simulator, a HistoryRecorder will be used as the simulator, with all keyword arguments forwarded to it, e.g.

    sim(mdp, max_steps=100) do s
        # ...
    end

will limit the simulation to 100 steps
"""
function sim end

function sim(polfunc::Function, mdp::MDP,
             initial_state=default_init_state(mdp);
             simulator=nothing,
             kwargs...
            )
    if simulator==nothing
        simulator = HistoryRecorder(;kwargs...)
    end
    policy = FunctionPolicy(polfunc)
    simulate(simulator, mdp, policy, initial_state)
end

function sim(polfunc::Function, pomdp::POMDP,
             initial_state=default_init_state(pomdp);
             simulator=nothing,
             initial_obs=default_init_obs(pomdp, initial_state),
             updater=PrimedPreviousObservationUpdater{Any}(initial_obs),
             kwargs...
            )
    if simulator==nothing
        simulator = HistoryRecorder(;initial_state=initial_state, kwargs...)
    end
    policy = FunctionPolicy(polfunc)
    simulate(simulator, pomdp, policy, updater)
end

function default_init_obs(p::POMDP, s)
    if implemented(generate_o, Tuple{typeof(p), typeof(s), typeof(Base.GLOBAL_RNG)})
        return generate_o(p, s, Base.GLOBAL_RNG)
    else
        return nothing
    end
end

@generated function default_init_state(p::Union{MDP,POMDP})
    if implemented(initial_state, Tuple{p, typeof(Base.GLOBAL_RNG)})
        return :(initial_state(p, Base.GLOBAL_RNG))
    else
        return quote
            error("""
                  Error in sim(::$(typeof(p))): No initial state specified.
                  
                  Please supply it as an argument after the mdp or define the method GenerativeModels.initial_state(::$(typeof(p)), ::$(typeof(Base.GLOBAL_RNG))) or define the method POMDPs.initial_state_distribution(::$(typeof(p))).

                  """)
        end
    end
end