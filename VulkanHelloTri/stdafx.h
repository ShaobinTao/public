// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#include "targetver.h"

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
// Windows Header Files:
#include <windows.h>

// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <vector>
#include <cassert>
#include <algorithm>
#include <fstream>

extern HINSTANCE	g_hInst;                                // current instance
extern HWND			g_windowHandle;


#define VK_USE_PLATFORM_WIN32_KHR
#include <vulkan\vulkan.h>

// TODO: reference additional headers your program requires here
