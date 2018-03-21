"""
Updater that stores the k most recent observations as the belief.
"""
struct KMarkovUpdater <: Updater
    k::Int
end

function initialize_belief{O}(bu::KMarkovUpdater, obs::O)
    obs_stacked = Vector{O}(bu.k)
    for i=1:bu.k
        obs_stacked[i] = obs
    end
    return obs_stacked
end

function initialize_belief{O}(bu::KMarkovUpdater, obs_vec::Vector{O})
    return obs_vec
end

function update{O}(bu::KMarkovUpdater, old_b::Vector{O}, action, obs::O)
    obs_stacked = Vector{O}(bu.k)
    for i=1:bu.k-1
        obs_stacked[i] = old_b[i+1]
    end
    obs_stacked[bu.k] = obs
    return obs_stacked
end
