## Feacalc.jl Full implementation of feature calculation for speech files. 
## (c) 2013 David A. van Leeuwen

## This program is free software: you can redistribute it and/or modify
##     it under the terms of the GNU General Public License as published by
##     the Free Software Foundation, version 3 of the License.

##     This program is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     GNU General Public License for more details.

##     You should have received a copy of the GNU General Public License
##     along with this program.  If not, see <http://www.gnu.org/licenses/>. 

## Feacalc.  Feature calculation as used for speaker and language recognition. 

using MFCCs
using SignalProcessing
using WAV
using Rasta

nrow(x) = size(x,1)
ncol(x) = size(x,2)

## compute features according to standard settingsm directly from a wav file. 
## this does channel at the time. 
function feacalc(wavfile::String; augtype=:ddelta, normtype=:warp, sadtype=:energy, defaults=:spkid_toolkit, dynrange::Real=30., nwarp::Int=399, chan=:mono)
    (x, sr) = wavread(wavfile)
    feacalc(x; augtype=agtype, normtype=normtype, sadtype=sadtype, defaults=defaults, dynrange=dynrange, nwarp=nwarp, chan=chan, sr=sr, source=wavfile)
end

## assume we have an array already
function feacalc(x::Array; augtype=:ddelta, normtype=:warp, sadtype=:energy, defaults=:spkid_toolkit, dynrange::Real=30., nwarp::Int=399, chan=:mono, sr::Real=8000.0, wavfile=":array")
    sr = convert(Float64, sr)       # more reasonable sr
    if ndims(x)>1
        nsamples, nchan = size(x)
        if chan == :mono
            x = vec(mean(x, 2))            # averave multiple channels for now
        elseif isa(chan, Integer) 
            if !(chan in 1:nchan)
                error("Bad channel specification: ", chan)
            end
            x = vec(x[:,chan])
        else
            error("Unknown channel specification: ", chan)
        end
    else
        nsamples, nchan = length(x), 1
    end
    ## save some metadata
    meta = {"nsamples" => nsamples, "sr" => sr, "source" => wavfile, "nchan" => nchan} 
    preemp = 0.97
    preemp ^= 16000. / sr

    ## basic features
    (m, pspec, params) = mfcc(x, sr, defaults)
    meta["totnframes"] = nrow(m)
    
    ## augment features
    if augtype==:delta || augtype==:ddelta
        d = deltas(m)
        if augtype==:ddelta
            dd = deltas(d)
            m = hcat(m, d, dd)
        else 
            m = hcat(m, d)
        end
    elseif augtype==:sdc
        m = sdc(m)
    end
    meta["augtype"] = string(augtype)

    if sadtype==:energy
        ## integrate power
        deltaf = size(pspec,2) / (sr/2)
        minfreqi = iround(300deltaf)
        maxfreqi = iround(4000deltaf)
        power = 10log10(sum(pspec[:,minfreqi:maxfreqi], 2))
    
        maxpow = maximum(power)
        speech = find(power .> maxpow - dynrange)
        params["dynrange"] = dynrange
    elseif sadtype==:none
        speech = 1:nrow(m)
    end
    meta["sadtype"] = string(sadtype)
    ## perform SAD
    m = m[speech,:]
    meta["speech"] = convert(Vector{Uint32}, speech)
    meta["nframes"] = nrow(m)
    meta["nfea"] = ncol(m)
    
    ## normalization
    if normtype==:warp
        m = warp(m, nwarp)
        params["warp"] = nwarp          # the default
    elseif normtype==:mvn
        znorm!(m,1)
    end
    meta["normtype"] = string(normtype)

    return(convert(Array{Float32},m), meta, params)
end

function feacalc(wavfile::String, application::Symbol; chan=:mono)
    if (application==:speaker)
        feacalc(wavfile; defaults=:spkid_toolkit, chan=chan)
    elseif application==:wbspeaker
        feacalc(wavfile; defaults=:wbspeaker, chan=chan)
    elseif (application==:language)
        feacalc(wavfile; defaults=:rasta, nwarp=299, augtype=:sdc, chan=chan)
    elseif (application==:diarization)
        feacalc(wavfile; defaults=:rasta, sadtype=:none, normtype=:mvn, augtype=:none, chan=chan)
    else
        error("Unknown application ", application)
    end
end

function sad(pspec::Array{Float64,2}, sr::Float64, method=:energy; dynrange::Float64=30.)
    deltaf = size(pspec,2) / (sr/2)
    minfreqi = iround(300deltaf)
    maxfreqi = iround(4000deltaf)
    power = 10log10(sum(pspec[:,minfreqi:maxfreqi], 2))
    maxpow = maximum(power)
    speech = find(power .> maxpow - dynrange)
end

## listen to SAD
function sad(wavfile::String, speechout::String, silout::String)
    (x, sr) = wavread(wavfile)
    sr = convert(Float64, sr)       # more reasonable sr
    x = mean(x, 2)[:,1]             # averave multiple channels for now
    (m, pspec, meta) = mfcc(x, sr; preemph=0)
    sp = sad(pspec, sr)
    sl = iround(meta["steptime"] * sr)
    xi = zeros(Bool, size(x))
    for (i = sp)
        xi[(i-1)*sl+(1:sl)] = true
    end
    y = x[find(xi)]
    wavwrite(y, sr, speechout)
    y = x[find(!xi)]
    wavwrite(y, sr, silout)
end
