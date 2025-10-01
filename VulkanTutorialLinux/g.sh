clear
glslc -fentry-point=main --target-env=vulkan1.4 -o ./shaders/vert.spv -g -fshader-stage=vertex  -O0  ./shaders/shader.vert
glslc -fentry-point=main --target-env=vulkan1.4 -o ./shaders/frag.spv -g -fshader-stage=fragment -O0 ./shaders/shader.frag
cd build
make
cd ..

