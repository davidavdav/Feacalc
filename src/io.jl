## io.jl
## (c) 2014 David A. van Leeuwen
##
## i/o functions for speech feature data

using HDF5

## always save data in Float32
## the functiona arguments are the same as the output of feacalc
function save{T<:FloatingPoint}(file::String, x::Matrix{T}, meta::Dict, params::Dict)
    fd = open(file, "w")
    fd["features/data"] = float32(x)
    fd["features/meta"] = meta
    fd["features/params"] = params
    close(fd)
end

## but always read into float64 
function load(file::String, meta=false, params=false)
    fd = open(file, "r")
    fea = float64(read(fd["features/data"]))
    if ! (meta || params)
        return fea
    end
    res = Any[fea]
    if meta
        push!(res, read(fd["features/meta"]))
    end
    if params
        push!(res, read(fd["features/params"]))
    end
    tuple(res...)
end
