# Forward Plus with Tile Shading

This sample implements a forward plus renderer optimized using tile shading and the SIMD quad groups APIs available in Metal with A11+ GPUs.

## Overview

Forward lighting can easily use MSAA, which is advantage over deferred lighting techniques.  However, unlike with deferred lighting,  in order to achieve an interactive framerate with a large number of lights, forward lighting must limit the number of lights applied to each fragment.  This sample demonstrates an optimal implementation for culling light volumes for each tile for and applying only the lights necessary to fragments within each tile.
