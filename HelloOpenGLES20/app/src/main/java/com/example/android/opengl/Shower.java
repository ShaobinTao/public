/*
 * Copyright (C) 2011 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.example.android.opengl;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.opengl.GLES20;
import android.opengl.GLUtils;

import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;

public class Shower {

    public Shower() {
        // prepare shaders and OpenGL program
        int vertexShader = MyGLRenderer.loadShader(
                GLES20.GL_VERTEX_SHADER, vertexShaderCode);
        int fragmentShader = MyGLRenderer.loadShader(
                GLES20.GL_FRAGMENT_SHADER, fragmentShaderCode);

        mProgram2 = GLES20.glCreateProgram();             // create empty OpenGL Program
        GLES20.glAttachShader(mProgram2, vertexShader);   // add the vertex shader to program
        GLES20.glAttachShader(mProgram2, fragmentShader); // add the fragment shader to program
        GLES20.glLinkProgram(mProgram2);                  // create OpenGL program executables

        MyGLRenderer.checkGlError("t1");

        GLES20.glUseProgram(mProgram2);

        MyGLRenderer.checkGlError("t1");


        mSampler = GLES20.glGetUniformLocation(mProgram2, "uTexture");
        MyGLRenderer.checkGlError("t1");
        muAlpha = GLES20.glGetUniformLocation(mProgram2, "uAlpha");
        MyGLRenderer.checkGlError("t1");
        muInfluence = GLES20.glGetUniformLocation(mProgram2, "uInfluence");
        MyGLRenderer.checkGlError("t1");
        muMVPMatrix = GLES20.glGetUniformLocation(mProgram2, "uMVPMatrix");
        MyGLRenderer.checkGlError("t1");

        mTexCoordHandle = GLES20.glGetAttribLocation(mProgram2, "aTextureCoord");
        mVertCoordHandle = GLES20.glGetAttribLocation(mProgram2, "aVertexCoord");

        MyGLRenderer.checkGlError("t1");

        GLES20.glGenBuffers(1, mTexCoordBuf, 0);
        GLES20.glGenBuffers(1, mVertCoordBuf, 0);
        GLES20.glGenBuffers(1, mIndexBuf, 0);

        MyGLRenderer.checkGlError("t1");

        // texture coordinates buffer
        {
            ByteBuffer buf = ByteBuffer.allocateDirect(texCoords.length * 4 );
            buf.order(  ByteOrder.nativeOrder() );
            textureBuffer = buf.asFloatBuffer();
            textureBuffer.put(texCoords);
            textureBuffer.position(0);
            GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, mTexCoordBuf[0]);
            GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, textureBuffer.capacity() * 4, textureBuffer, GLES20.GL_STATIC_DRAW );
            GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0);
        }
        MyGLRenderer.checkGlError("t1");

        {
            ByteBuffer buf = ByteBuffer.allocateDirect(vertCoords.length * 4 );
            buf.order(  ByteOrder.nativeOrder() );
            vertBuffer = buf.asFloatBuffer();
            vertBuffer.put(vertCoords);
            vertBuffer.position(0);
            GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, mVertCoordBuf[0]);
            GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, vertBuffer.capacity() * 4, vertBuffer, GLES20.GL_STATIC_DRAW );
            GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0);
        }
        MyGLRenderer.checkGlError("t1");
        {
            ByteBuffer buf = ByteBuffer.allocateDirect(vertIndex.length * 4 );
            buf.order(  ByteOrder.nativeOrder() );
            indexBuffer = buf.asIntBuffer();
            indexBuffer.put(vertIndex);
            indexBuffer.position(0);

            GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, mIndexBuf[0]);
            GLES20.glBufferData(GLES20.GL_ELEMENT_ARRAY_BUFFER, indexBuffer.capacity() * 4, indexBuffer, GLES20.GL_STATIC_DRAW );
            GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0);
        }
        MyGLRenderer.checkGlError("t1");
    }

    public void draw() {
        MyGLRenderer.checkGlError("t1");
        GLES20.glEnable(GLES20.GL_DEPTH_TEST)                                                                                                                                                                                                              ; // 225392
        MyGLRenderer.checkGlError("t1");
        GLES20.glDepthFunc(GLES20.GL_LESS)                                                                                                                                                                                                                ; // 225393
        MyGLRenderer.checkGlError("t1");
        GLES20.glDepthMask(true)                                                                                                                                                                                                                ; // 225394
        MyGLRenderer.checkGlError("t1");
        GLES20.glClearDepthf(1.0f)                                                                                                                                                                                                                     ; // 225395
        MyGLRenderer.checkGlError("t1");
        GLES20.glEnable(GLES20.GL_CULL_FACE)                                                                                                                                                                                                               ; // 225397
        MyGLRenderer.checkGlError("t1");
        GLES20.glCullFace(GLES20.GL_BACK)                                                                                                                                                                                                                 ; // 225398
        MyGLRenderer.checkGlError("t1");
        GLES20.glFrontFace(GLES20.GL_CCW)                                                                                                                                                                                                                 ; // 225399
        MyGLRenderer.checkGlError("t1");
        GLES20.glEnable(GLES20.GL_BLEND)                                                                                                                                                                                                                   ; // 225400
        MyGLRenderer.checkGlError("t1");
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE)                                                                                                                                                                                        ; // 225401
        MyGLRenderer.checkGlError("t1");
        GLES20.glDisable(GLES20.GL_DEPTH_TEST)                                                                                                                                                                                                             ; // 225402
        MyGLRenderer.checkGlError("t1");
        GLES20.glDepthMask(false)                                                                                                                                                                                                               ; // 225403
        MyGLRenderer.checkGlError("t1");

MyGLRenderer.checkGlError("t1");
        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, 0)                                                                                                                                                                                   ; // 225529
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)                                                                                                                                                                                           ; // 225530
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)                                                                                                                                                                                           ; // 225531
        MyGLRenderer.checkGlError("t1");
        GLES20.glUseProgram(mProgram2)                                                                                                                                                                                                                 ; // 225532
        MyGLRenderer.checkGlError("t1");
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)                                                                                                                                                                                                     ; // 225533
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[0]);
        GLES20.glUniform1i(mSampler,0)                                                                                                                                                                                                            ; // 225535
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, mTexCoordBuf[0])                                                                                                                                                                                          ; // 225536
        GLES20.glEnableVertexAttribArray(mTexCoordHandle)                                                                                                                                                                                                       ; // 225537
        GLES20.glVertexAttribPointer(mTexCoordHandle, 2, GLES20.GL_FLOAT, false, 0, 0)                                                                                                                                       ; // 225538

        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, mVertCoordBuf[0])                                                                                                                                                                                          ; // 225539
        GLES20.glEnableVertexAttribArray(mVertCoordHandle)                                                                                                                                                                                                       ; // 225540
        GLES20.glVertexAttribPointer(mVertCoordHandle, 3, GLES20.GL_FLOAT, false, 0, 0)                                                                                                                                       ; // 225541
        GLES20.glUniform1f(muAlpha, 0.32013953f)                                                                                                                                                                                                   ; // 225542
        GLES20.glUniform1f(muInfluence, 0.3f)                                                                                                                                                                                                          ; // 225543
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)                                                                                                                                                                                           ; // 225544
//        float v1[] = {-4.291935f, 0.0f, 8.8892065E-8f, 8.742278E-8f, 0.0f, 2.4142134f, 0.0f, 0.0f, 3.7521286E-7f, 0.0f, 1.0168067f, 1.0f, -1.9778945f, -3.9805202f, -0.18765044f, 1.7989224f};
        float v1[] = {-4.291935f, 0.0f, 8.8892065E-8f, 8.742278E-8f, 0.0f, 2.4142134f, 0.0f, 0.0f, 3.7521286E-7f, 0.0f, 1.0168067f, 1.0f, -1.3661366f, 1.1819212f, 0.2156434f, 2.1955502f};


        GLES20.glUniformMatrix4fv(muMVPMatrix, 1, false, v1, 0)              ; // 225545
        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, mIndexBuf[0])                                                                                                                                                                                  ; // 225546
        GLES20.glDrawElements(GLES20.GL_TRIANGLES, 6, GLES20.GL_UNSIGNED_INT, 0)                                                                                                                                                           ; // 225547








        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, 0)      ; // 227429
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)              ; // 227430
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)              ; // 227431
        GLES20.glDisable(GLES20.GL_BLEND)                                     ; // 227432
        GLES20.glDisable(GLES20.GL_CULL_FACE)                                 ; // 227433
        GLES20.glEnable(GLES20.GL_DEPTH_TEST)                                 ; // 227434
        GLES20.glDepthFunc(GLES20.GL_LESS)                                   ; // 227435
        GLES20.glDepthMask(false)                                  ; // 227436
    }


    public void loadTexture(Context context) {
        InputStream imageStream = context.getResources().openRawResource(  R.drawable.rain );

        Bitmap bitmap = null;

        try {
            bitmap = BitmapFactory.decodeStream(imageStream);
        } catch (Exception e) {

        } finally {
            try {
                imageStream.close();
                imageStream = null;
            } catch (Exception e) {

            }
        }

        GLES20.glGenTextures(1, textures, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[0]);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_NEAREST);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_REPEAT);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_REPEAT);

        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0);
        bitmap.recycle();
    }

    private final String vertexShaderCode =
            "uniform mat4 uMVPMatrix;                       " +
                    "attribute vec2 aTextureCoord;                  " +
                    "attribute vec4 aVertexCoord;                   " +
                    "varying vec2 vTextureCoord;                    " +
                    "                                               " +
                    "void main() {                                  " +
                    "    gl_Position = uMVPMatrix * aVertexCoord;   " +
                    "    vTextureCoord = aTextureCoord;             " +
                    "}";

    private final String fragmentShaderCode = "" +
            "precision highp float;                                                              " +
            "const float ONE = 1.0;                                                              " +
            "uniform float uAlpha;                                                               " +
            "uniform float uInfluence;                                                           " +
            "uniform sampler2D uTexture;                                                         " +
            "varying vec2 vTextureCoord;                                                         " +
            "void main() {                                                                       " +
            "    vec4 color = texture2D(uTexture, vTextureCoord);                                " +
//staotemp            "    gl_FragColor = vec4(color.rgb, (color.a + uInfluence*(ONE - color.a))*uAlpha);  " +
            "    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);  " +
            "}";




    private final int mProgram2;
    private int[] textures = new int[1];

    int   mSampler;
    int   muAlpha;
    int   muInfluence;
    int   muMVPMatrix;

    private int mTexCoordHandle;
    private int mVertCoordHandle;

    private int[] mTexCoordBuf = new int[1];
    private int[] mVertCoordBuf = new int[1];
    private int[] mIndexBuf = new int[1];



    // texture coordinates
    private float texCoords[] = {        1,      1,        1,     0,        0,      1,        0,     0 };
    // 2 floats
    static int texStride = 2 * 4;
    private final FloatBuffer textureBuffer;

    // vert coord
///*  staotemp
    private float vertCoords[] = {
            -0.03f,     -0.03f,     0,
            -0.03f,     0.03f,     0,
            0.03f,     -0.03f,     0,
            0.03f,     0.03f,     0 };
//*/
/*
    private float vertCoords[] = {
            -1f,     -1,     0,
            -1,     1f,     0,
            1,     -1,     0,
            1,     1f,     0 };
*/
    private final FloatBuffer vertBuffer;

    // vert indices
    private int vertIndex[] = {
            2, 0, 3, 3, 0, 1
    };
    private final IntBuffer indexBuffer;




}
