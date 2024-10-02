
# follow instructions at https://vulkan-tutorial.com/en/Development_environment#page_MacOS

# a few modifications
    - glfw/glm may not be installed to /use/local/include. run 
        ~ % brew info glfw
        /opt/homebrew/Cellar/glfw/3.4 (16 files, 871.4KB) *

        ~ % brew info glm 
        /opt/homebrew/Cellar/glm/1.0.1 (1,931 files, 22.6MB) *

        to find the right paths
    - In Schedme, also add 
        DYLD_LIBRARY_PATH=/Users/<home dir>/VulkanSDK/1.3.290.0/macOS/lib
        otherwise, you will see run time errors

    dyld[81058]: Library not loaded: @rpath/libvulkan.1.dylib
  Referenced from: <E708BF05-CEA5-3CCB-B8BF-F2C4A1C1627E> /Users/dev/Library/Developer/Xcode/DerivedData/vkToDel-bfpbgoktrqnxvyernqcgewtpqqhv/Build/Intermediates.noindex/InstallIntermediates/macosx/InstallableProducts/usr/local/bin/vkToDel
  Reason: tried: '/Users/dev/Library/Developer/Xcode/DerivedData/vkToDel-bfpbgoktrqnxvyernqcgewtpqqhv/Build/Intermediates.noindex/InstallIntermediates/macosx/Products/Debug/libvulkan.1.dylib' (no such file), '/usr/lib/system/introspection/libvulkan.1.dylib' (no such file, not in dyld cache)        

# env 
    macOS: 15.0
    