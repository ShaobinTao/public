//
// Created by s00407713 on 4/28/2017.
//
#include <vector>
#include <cassert>
#include <android/log.h>
#include <android_native_app_glue.h>
#include "vulkan_wrapper.h"

// Android log function wrappers
static const char* kTAG = "HelloTri";
#define LOGI(...) \
  ((void)__android_log_print(ANDROID_LOG_INFO, kTAG, __VA_ARGS__))
#define LOGW(...) \
  ((void)__android_log_print(ANDROID_LOG_WARN, kTAG, __VA_ARGS__))
#define LOGE(...) \
  ((void)__android_log_print(ANDROID_LOG_ERROR, kTAG, __VA_ARGS__))

// We will call this function the window is opened.
// This is where we will initialise everything
bool initialized_ = false;
bool initialize(android_app* app);

// Functions interacting with Android native activity
void android_main(struct android_app* state);
void terminate();
void handle_cmd(android_app* app, int32_t cmd);

void android_main(struct android_app* app) {
    app_dummy();

    app->onAppCmd = handle_cmd;

    int events;
    android_poll_source* source;
    do {
        if (ALooper_pollAll(initialized_? 1: 0, nullptr, &events, (void**)&source) >= 0) {
            if (source != NULL) source->process(app, source);
        }
    } while (app->destroyRequested == 0);



}

bool initialize(android_app* app) {
    // Load Android vulkan and retrieve vulkan API function pointers
    if (!InitVulkan()) {
        LOGE("Vulkan is unavailable, install vulkan and re-start");
        return false;
    }

    initialized_ = true;
    return 0;
}

void terminate() {

    initialized_ = false;
}


// Process the next main command.
void handle_cmd(android_app* app, int32_t cmd) {
    switch (cmd) {
        case APP_CMD_INIT_WINDOW:
            // The window is being shown, get it ready.
            initialize(app);
            break;
        case APP_CMD_TERM_WINDOW:
            // The window is being hidden or closed, clean it up.
            terminate();
            break;
        default:
            LOGI("event not handled: %d", cmd);
    }
}
