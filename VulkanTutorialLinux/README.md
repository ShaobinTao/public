# First CL, unmodified files
- a copy of files from https://github.com/Overv/VulkanTutorial
- copies of stb_image.h, tiny_obj_loader.h




source VulkanTutorialLinux/vulkan.sh

# create Makefile
mkdir build; cd build;
/VulkanTutorialLinux/build> cmake ../CMakeLists.txt -DCMAKE_BUILD_TYPE=Debug

# build
VulkanTutorialLinux/g.sh to build

glslangValidator -R --target-env vulkan1.3 shader_base.vert
glslangValidator -R --target-env vulkan1.3 shader_base.frag


* to run the exe
VulkanTutorialLinux/build> ./test


* See launch.json for VS Code debugging settings


