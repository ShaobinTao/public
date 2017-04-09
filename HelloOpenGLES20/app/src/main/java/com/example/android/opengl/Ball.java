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

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

import android.opengl.GLES20;
import android.opengl.GLES30;


/**
 * A two-dimensional triangle for use as a drawn object in OpenGL ES 2.0.
 */
public class Ball {

    private final String vertexShaderCode =
            "precision mediump float;"+
                    "attribute vec3 aVertexPosition;"+
                    "uniform mat4 MVPMatrix;"+
                    "varying vec4 pos;"+

                    "attribute vec2 aTextureCoord;"+
                    "varying vec2 vTextureCoord;"+

                    "uniform vec4 agRect;"+	// max, radius, width, height for current obj
                    "varying vec4 fDimen;"+	// for agRect

                    "void main(void) {"+
                    "    vec4 p = vec4(aVertexPosition, 1.0);"+
                    "    gl_Position = MVPMatrix * p;"+

                    "    pos = p;"+

                    "    vTextureCoord = aTextureCoord;"+
                    "    fDimen = agRect;"+
                    "}";

    private final String fragmentShaderCode = "" +
            "precision mediump float;"+
            "varying vec4 pos;"+

            "uniform float gr;"+
            "varying vec4 fDimen;"+	// max/radius/width/height
            "uniform vec4 paintColor;"+	// paintColor for current obj
            "uniform vec4 attrs;"+		//order by type/mixType/alpha/rotateAngle

            "void main(void) {"+
            //float alpha = circle.w;
            "   float radius = fDimen.y;"+
            "   float alpha = attrs.z;"+
            "   float dis = length(pos.xy);"+
            "   float gradient = 1.0-smoothstep(radius-gr,radius,dis);"+
            "   if(gradient==0.0 || alpha==0.0)"+
            "       discard;"+
            "   float fa = gradient * paintColor.a * attrs.z;"+
            "   gl_FragColor = vec4(paintColor.rgb * fa, fa );"+

            "}";
    /*
    ﻿0, 0, , agRect, GL_FLOAT_VEC4, [28.0, 12.0, 28.0, 28.0]
1, 1, , MVPMatrix, GL_FLOAT_MAT4, [[2.4992561, 0.0, 0.0, 905.51935],
 [0.0, -2.3594375, 0.0, -475.93997],
 [0.0, 0.0, -3.0000002, 500.00024],
 [0.0, 0.0, -1.0, 1500.0]]
2, 2, , attrs, GL_FLOAT_VEC4, [0.0, 0.0, 0.75888425, 0.0]
3, 3, , paintColor, GL_FLOAT_VEC4, [0.7764706, 0.77254903, 0.77254903, 0.67058825]
4, 4, , gr, GL_FLOAT, [0.0]

﻿0 aVertexPosition=[-14.0, -14.0, 0.0]
1 aVertexPosition=[-14.0, 14.0, 0.0]
2 aVertexPosition=[14.0, -14.0, 0.0]
3 aVertexPosition=[14.0, 14.0, 0.0]
     */

    private final FloatBuffer vertexBuffer;
    private final int mProgram;
    private int mPositionHandle;
    private int mColorHandle;
    private int mRectHandle;
    private int mGrHandle;
    private int mAttrHandle;
    private int mMVPMatrixHandle;

    // number of coordinates per vertex in this array
    static final int COORDS_PER_VERTEX = 3;
    static float triangleCoords[] = {
            -14.0f,  -14.0f, 0.0f,
            -14.0f, 14.0f, 0.0f,
            14.0f, -14.0f, 0.0f,
            14.0f, 14.0f, 0.0f
    };
    private final int vertexCount = triangleCoords.length / COORDS_PER_VERTEX;
    private final int vertexStride = COORDS_PER_VERTEX * 4; // 4 bytes per vertex

    float color[] = { 1.0f, 0.77254903f, 0.77254903f, 1.0f };

    /**
     * Sets up the drawing object data for use in an OpenGL ES context.
     */
    public Ball() {
        // initialize vertex byte buffer for shape coordinates
        ByteBuffer bb = ByteBuffer.allocateDirect(
                // (number of coordinate values * 4 bytes per float)
                triangleCoords.length * 4);
        // use the device hardware's native byte order
        bb.order(ByteOrder.nativeOrder());

        // create a floating point buffer from the ByteBuffer
        vertexBuffer = bb.asFloatBuffer();
        // add the coordinates to the FloatBuffer
        vertexBuffer.put(triangleCoords);
        // set the buffer to read the first coordinate
        vertexBuffer.position(0);

        // prepare shaders and OpenGL program
        int vertexShader = MyGLRenderer.loadShader(
                GLES20.GL_VERTEX_SHADER, vertexShaderCode);
        int fragmentShader = MyGLRenderer.loadShader(
                GLES20.GL_FRAGMENT_SHADER, fragmentShaderCode);

        mProgram = GLES20.glCreateProgram();             // create empty OpenGL Program
        GLES20.glAttachShader(mProgram, vertexShader);   // add the vertex shader to program
        GLES20.glAttachShader(mProgram, fragmentShader); // add the fragment shader to program
        GLES20.glLinkProgram(mProgram);                  // create OpenGL program executables

        MyGLRenderer.checkGlError("t1");

        GLES20.glUseProgram(mProgram);
        MyGLRenderer.checkGlError("t2");

        // get handle to vertex shader's vPosition member
        mPositionHandle = GLES20.glGetAttribLocation(mProgram, "aVertexPosition");
        mColorHandle = GLES20.glGetUniformLocation(mProgram, "paintColor");
        mRectHandle = GLES20.glGetUniformLocation(mProgram, "agRect");
        mAttrHandle = GLES20.glGetUniformLocation(mProgram, "attrs");
        mGrHandle = GLES20.glGetUniformLocation(mProgram, "gr");
        mMVPMatrixHandle = GLES20.glGetUniformLocation(mProgram, "MVPMatrix");

        // Enable a handle to the triangle vertices
        GLES20.glEnableVertexAttribArray(mPositionHandle);

        // Prepare the triangle coordinate data
        GLES20.glVertexAttribPointer(
                mPositionHandle, COORDS_PER_VERTEX,
                GLES20.GL_FLOAT, false,
                vertexStride, vertexBuffer);

        GLES20.glDisableVertexAttribArray(mPositionHandle);
    }

    /**
     * Encapsulates the OpenGL ES instructions for drawing this shape.
     *
     * @param mvpMatrix - The Model View Project matrix in which to draw
     * this shape.
     */
    public void draw() {
        // Add program to OpenGL environment
        GLES20.glViewport(0,0,1080,1144);
        int k = 60;
        GLES20.glEnable(GLES20.GL_BLEND);
        GLES20.glBlendFunc(GLES20.GL_ONE,GLES20.GL_ONE_MINUS_SRC_ALPHA);
        for(int i=0;i<k;i++) {

            GLES20.glUseProgram(mProgram);

            // Enable a handle to the triangle vertices
            GLES20.glEnableVertexAttribArray(mPositionHandle);

            // Prepare the triangle coordinate data
            vertexBuffer.position(0);
            GLES20.glVertexAttribPointer(
                    mPositionHandle, COORDS_PER_VERTEX,
                    GLES20.GL_FLOAT, false,
                    vertexStride, vertexBuffer);

            // get handle to fragment shader's vColor member
            GLES20.glUniform4fv(mColorHandle, 1, color, 0);

            GLES20.glUniform4f(mRectHandle, 28.0f, 12.0f, 28.0f, 28.0f);

            GLES20.glUniform4f(mAttrHandle, 0.0f, 0.0f, 0.75888425f, 0.0f);

            GLES20.glUniform1f(mGrHandle, 0);

            // get handle to shape's transformation matrix
            MyGLRenderer.checkGlError("glGetUniformLocation");

            // Apply the projection and view transformation
            float mvpMatrix[] = new float[]{0.6081378f,
                    0.0f,
                    0.0f,
                    0.0f,
                    0.0f,
                    -0.5741161f,
                    0.0f,
                    0.0f,
                    0.0f,
                    0.0f,
                    -3.0000002f,
                    -1.0f,
                    515.1042f,
                    -610.2643f,
                    500.00024f,
                    1500.0f};

            GLES20.glUniformMatrix4fv(mMVPMatrixHandle, 1, false, mvpMatrix, 0);
            MyGLRenderer.checkGlError("glUniformMatrix4fv");

            // Draw the triangle
                GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, vertexCount);
            //GLES30.glDrawArraysInstanced(GLES30.GL_TRIANGLE_STRIP, 0, vertexCount,60);

        }
        GLES20.glDisable(GLES20.GL_BLEND);

    }

}
