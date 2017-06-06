//
// Copyright 2011 Tero Saarni
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#ifndef RENDERER_H
#define RENDERER_H

#include <pthread.h>
#include <EGL/egl.h> // requires ndk r5 or newer
#include <GLES/gl.h>
#define GL_GLEXT_PROTOTYPES
#include <gles2/gl2ext.h>


class Renderer {

public:
    PFNGLGENQUERIESEXTPROC  glGenQueriesEXT;
    PFNGLDELETEQUERIESEXTPROC   glDeleteQueriesEXT;
    PFNGLISQUERYEXTPROC    glIsQueryEXT;
    PFNGLBEGINQUERYEXTPROC    glBeginQueryEXT;
    PFNGLENDQUERYEXTPROC    glEndQueryEXT;
    PFNGLQUERYCOUNTEREXTPROC    glQueryCounterEXT;
    PFNGLGETQUERYIVEXTPROC    glGetQueryivEXT;
    PFNGLGETQUERYOBJECTIVEXTPROC    glGetQueryObjectivEXT;
    PFNGLGETQUERYOBJECTUIVEXTPROC    glGetQueryObjectuivEXT;
    PFNGLGETQUERYOBJECTI64VEXTPROC    glGetQueryObjecti64vEXT;
    PFNGLGETQUERYOBJECTUI64VEXTPROC    glGetQueryObjectui64vEXT;
    GLuint     queries[2];


    Renderer();
    virtual ~Renderer();

    // Following methods can be called from any thread.
    // They send message to render thread which executes required actions.
    void start();
    void stop();
    void setWindow(ANativeWindow* window);
    
    
private:

    enum RenderThreadMessage {
        MSG_NONE = 0,
        MSG_WINDOW_SET,
        MSG_RENDER_LOOP_EXIT
    };

    pthread_t _threadId;
    pthread_mutex_t _mutex;
    enum RenderThreadMessage _msg;
    
    // android window, supported by NDK r5 and newer
    ANativeWindow* _window;

    EGLDisplay _display;
    EGLSurface _surface;
    EGLContext _context;
    GLfloat _angle;
    
    // RenderLoop is called in a rendering thread started in start() method
    // It creates rendering context and renders scene until stop() is called
    void renderLoop();
    
    bool initialize();
    void destroy();

    void drawFrame();

    // Helper method for starting the thread 
    static void* threadStartCallback(void *myself);



/*
    static float vertCoords[] = {
            -1, 1, 0,
            -1, -1, 0,
            1, -1, 0,
            1, 1, 0 };

    short vertIndices[] = {0,1,2,0,2,3};
    float texture[] = {
                -1f, 1f,
                -1f, -1f,
                1f, -1f,
                1f, 1f,
        };

    char* vertexShaderCode = "uniform mat4 uMVPMatrix;" \
        "attribute vec4 vPosition;" \
        "attribute vec2 TexCoordIn;" \
        "varying vec2 TexCoordOut;" \
        "void main() {" \
        " gl_Position = uMVPMatrix * vPosition;" \
        " TexCoordOut = TexCoordIn;" \
        "}";

    char* fragmentShaderCode = "precision mediump float;" \
        "uniform vec4 vColor;" \
        "uniform sampler2D S1;" \
        "uniform float scroll;" \
        "varying vec2 TexCoordOut;" \
        "void main() {" \
        "gl_FragColor = texture2D(S1, vec2(TexCoordOut.x,TexCoordOut.y + scroll) );" \
        "}";

public int[] textures = new int[1];
private final FloatBuffer textureBuffer;
    static final int COORDS_PER_TEXTURE = 2;
    static int textureStride = COORDS_PER_TEXTURE * 4;


    final FloatBuffer vertexBuffer;
    final ShortBuffer drawListBuffer;
    final int mProgram;
    int mPositionHandle;
    int mColorHandle;
    int mMVPMatrixHandle;

    final int COORDS_PER_VERTEX = 3;
    final int vertexStride = COORDS_PER_VERTEX * 4;

*/



};

#endif // RENDERER_H
