
cmake_minimum_required(VERSION 3.4.1)

include_directories(${ANDROID_NDK}/sources/third_party/vulkan/src/include)
include_directories(${ANDROID_NDK}/sources/third_party/vulkan/src/common)

add_library(app-glue STATIC
    ${ANDROID_NDK}/sources/android/native_app_glue/android_native_app_glue.c
    ${ANDROID_NDK}/sources/third_party/vulkan/src/common/vulkan_wrapper.cpp )

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++11")

add_library(HelloTri SHARED
            main.cpp)

target_include_directories(HelloTri PRIVATE
    ${ANDROID_NDK}/sources/android/native_app_glue)

target_link_libraries(HelloTri
                      android
                      app-glue
                      EGL
                      GLESv1_CM
                      log)
