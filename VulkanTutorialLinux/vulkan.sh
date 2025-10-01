# script to set correct paths for developing vulkan on gLinux


# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/partner-moohan-android-14-dev/out/soong/.intermediates/external/shaderc/glslang/glslang/linux_glibc_x86_64_static:~/partner-moohan-android-14-dev/out/soong/.intermediates/external/shaderc/shaderc/shaderc_util/linux_glibc_x86_64_static:~/partner-moohan-android-14-dev/out/soong/.intermediates/external/shaderc/shaderc/shaderc/linux_glibc_x86_64_static/:~/partner-moohan-android-14-dev/out/soong/.intermediates/external/shaderc/spirv-tools/SPIRV-Tools/linux_glibc_x86_64_static/:~/partner-moohan-android-14-dev/out/host/linux-x86/lib64/:~/partner-moohan-android-14-dev/out/soong/.intermediates/external/shaderc/spirv-tools/spirv-opt/linux_glibc_x86_64/

VKSDK=~/vulkansdk-linux-x86_64-1.4.321.1

export PATH=/usr/local/google/home/shaobin/github/shaderc_gg/bin:$VKSDK/x86_64/bin:$PATH



