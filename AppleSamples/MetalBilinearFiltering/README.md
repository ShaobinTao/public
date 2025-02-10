#  <#Title#>

This project tries to 


- Source texture. 5 x 1 that has content [1 2 3 4 5]

- Target texture   5 x 1

- Full screen render

- Write [sampled_source_texture_value, passed_in_UV, 1] to target texture

- fragmentShader did not make any changes to passed_in_UV, Target texture has the perfect [1 2 3 4 5]

It proves there is no need to adjust passed in UV by 0.5/(texture width, texture height)


