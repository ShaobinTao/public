cmake_minimum_required(VERSION 3.31.6)

project(VulkanTutorialLinux VERSION 1.0.0 LANGUAGES CXX)

# Set the build type to Debug. For single-configuration generators like Makefiles,
# this sets the default configuration.
# For more flexibility, you can also pass this on the command line:
# cmake -DCMAKE_BUILD_TYPE=Debug ..
set(CMAKE_BUILD_TYPE Debug)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Vulkan REQUIRED)
find_package(glfw3 3.3 REQUIRED)

# Append flags for the Debug build type to ensure no optimization and full debug symbols.
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0 -g3")

add_executable(test
    ${PROJECT_SOURCE_DIR}/30_multisampling.cpp

)

target_include_directories(test PUBLIC
    ${PROJECT_SOURCE_DIR}/include
    ${Vulkan_INCLUDE_DIRS}
)

target_link_libraries(test
    glfw
    Vulkan::Vulkan
)
