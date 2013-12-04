Feacalc
=======

This module has methods that set parameters for feature extraction in standard configurations.  This is very specific to the application. 

```julia
using Feacalc 

feacalc(wavfile; augtype, normtype, sadtype defaults, dynrange, nwarp)
```

Extracts speech features using a number of parameter settings:

 - `augtype`: Augmentation of features, one of `:none`, `:delta`, `ddelta`, or `:sdc` for no augmentation, derivatives and second derivatives of the features, and 'shifted delta coefficients'. 
 - `normtype`: Normalization of features, one of `:none`, `:warp` or `:mvn`, for no normalization, feature warping, mean and variance normalization (z-norm).
 - `sadtype`: Speech Activity Detection, one of `:none` or `:energy`, for no SAD or energy-based SAD, using the parameter `dynrange`, the range (in dB) of the below the maximum energy in the signal that still is considered speech.  
 - `defaults`: MFCC extraction defaults, one of `:spkid_toolkit`, `:wbspeaker`, `:rasta`, `:htk` for features from the RUN speaker recogntion system, wideband speaker recogniiton, default settings of rastamat, or default HTK type features. 

```julia
feacalc(wavfile, application)
```

Extracts features for applications `:speaker`, `:wbspeaker` or `:diarization`.  
