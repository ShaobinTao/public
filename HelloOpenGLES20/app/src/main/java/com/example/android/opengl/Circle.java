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
public class Circle {

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

    private final String fragmentShaderCode =
            "#ifdef GL_ES\n"+
//                    "	#extension GL_OES_standard_derivatives : enable\n"+
                    "	#ifdef GL_FRAGMENT_PRECISION_HIGH\n"+
                    "		precision highp float;\n"+
                    "	#else\n"+
                    "		precision mediump float;\n"+
                    "	#endif\n"+
                    "#endif\n"+

                    "varying vec4 pos;"+
                    ""+
                    "varying vec4 fDimen;" +	// max/radius/width/height
                    "uniform vec4 attrs;" +		//order by type/mixType/alpha/rotateAngle
                    "uniform mat4 circles;"+
                    "uniform vec4 paintColor;" +	// paintColor for current obj
                    ""+
                    "uniform vec3 startColor;"+// = vec3(1.0, 0.0, 0.0);"+
                    "uniform vec3 endColor;"+// = vec3(1.0, 1.0, 0.0);"+
                    ""+
                    "uniform float criticleValue;"+
                    "uniform float power;"+
                    ""+
                    "float circle_distance(in vec2 xy, in vec2 cxy, in float r){"+
                    "	float d = distance(xy, cxy);"+
                    "    highp float v = pow(r/d,power);"+

                            "    return v;"+
                    "}"+
                    ""+
                    "void fillColor2(in float it){"+
                    "    float halo = smoothstep(-criticleValue - 5.0,-criticleValue,-it);"+
                    "    halo = pow(halo , 6.0);"+
                    ""+
                    "    "+
                    "    float haloAlpha = 0.45;"+
                    "    halo = haloAlpha + halo * (1.0 - haloAlpha);"+
                    "    "+
                    "	float gr = smoothstep(criticleValue-0.01, criticleValue, it);"+
                    "	vec4 bubleColor = vec4(vec3(1.0),paintColor.a) * gr;"+
                    ""+
                    "    gl_FragColor = bubleColor * halo * attrs.z;"+
                    "}"+
                    ""+
                    "void main(void) {"+
                    "    float it = 0.0;"+

                    "        it += circle_distance(pos.xy, circles[0].xy, circles[0].z);"+
                    "        it += circle_distance(pos.xy, circles[1].xy, circles[1].z);"+
                    "        it += circle_distance(pos.xy, circles[2].xy, circles[2].z);"+
                    "        it += circle_distance(pos.xy, circles[3].xy, circles[3].z);"+
                                        /*

                    "    for(int i=0;i<4;i++){"+
                    "        vec4 circle = circles[i];"+
                    "        float s = circle_distance(pos.xy, circle.xy, circle.z);"+
                    "        it = it + s;"+
                    "    }"+
              */
                    "	"+
                    "    fillColor2(it);"+
                    "  "+
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
    private int mCircleHandle;
    private int mCValueHandle;
    private int mPowerHandle;
    private int mAttrsHandle;
    private int mMVPMatrixHandle;

    // number of coordinates per vertex in this array
    static final int COORDS_PER_VERTEX = 3;
    static float triangleCoords[] = {
            -360.0f,  -360.0f, 0.0f,
            -360.0f, 360.0f, 0.0f,
            360.0f, -360.0f, 0.0f,
            360.0f, 360.0f, 0.0f
    };
    private final int vertexCount = triangleCoords.length / COORDS_PER_VERTEX;
    private final int vertexStride = COORDS_PER_VERTEX * 4; // 4 bytes per vertex

    float color[] = { 1.0f, 1.0f, 1.0f, 1.0f };

    /**
     * Sets up the drawing object data for use in an OpenGL ES context.
     */
    public Circle() {
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
        MyGLRenderer.checkGlError("glGetUniformLocation");

        GLES20.glAttachShader(mProgram, vertexShader);   // add the vertex shader to program
        MyGLRenderer.checkGlError("glGetUniformLocation");
        GLES20.glAttachShader(mProgram, fragmentShader); // add the fragment shader to program
        GLES20.glLinkProgram(mProgram);                  // create OpenGL program executables
        MyGLRenderer.checkGlError("glGetUniformLocation");
        GLES20.glUseProgram(mProgram);
        MyGLRenderer.checkGlError("glGetUniformLocation");

        // get handle to vertex shader's vPosition member
        mPositionHandle = GLES20.glGetAttribLocation(mProgram, "aVertexPosition");
        MyGLRenderer.checkGlError("glGetUniformLocation");

        mRectHandle = GLES20.glGetUniformLocation(mProgram, "agRect");
        MyGLRenderer.checkGlError("glGetUniformLocation");

        mMVPMatrixHandle = GLES20.glGetUniformLocation(mProgram, "MVPMatrix");
        MyGLRenderer.checkGlError("glGetUniformLocation");

        mCircleHandle = GLES20.glGetUniformLocation(mProgram, "circles");
        mColorHandle = GLES20.glGetUniformLocation(mProgram, "paintColor");
        MyGLRenderer.checkGlError("glGetUniformLocation");

        mCValueHandle = GLES20.glGetUniformLocation(mProgram, "criticleValue");
        mPowerHandle = GLES20.glGetUniformLocation(mProgram, "power");
        MyGLRenderer.checkGlError("glGetUniformLocation");

        mAttrsHandle = GLES20.glGetUniformLocation(mProgram, "attrs");

        MyGLRenderer.checkGlError("glGetUniformLocation");

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
        int k = 2;
        GLES20.glEnable(GLES20.GL_BLEND);
        GLES20.glBlendFunc(GLES20.GL_ONE,GLES20.GL_ONE_MINUS_SRC_ALPHA);
        GLES20.glUseProgram(mProgram);

        for(int i=0;i<k;i++) {


            // Enable a handle to the triangle vertices
            GLES20.glEnableVertexAttribArray(mPositionHandle);

            // Prepare the triangle coordinate data
            GLES20.glVertexAttribPointer(
                    mPositionHandle, COORDS_PER_VERTEX,
                    GLES20.GL_FLOAT, false,
                    vertexStride, vertexBuffer);

/*
* ﻿0, 0, , MVPMatrix, GL_FLOAT_MAT4, [[-1.5943183, -4.140375, 0.0, -1.13028065E-4],
 [-3.9087458, 1.5051256, 0.0, 1.06704814E-4],
 [0.0, -0.0, -3.0000002, 500.00024],
 [0.0, 0.0, -1.0, 1500.0]]
1, 1, , power, GL_FLOAT, [2.0]
2, 2, , criticleValue, GL_FLOAT, [1.1875]
3, 3, , paintColor, GL_FLOAT_VEC4, [1.0, 1.0, 1.0, 1.0]
4, 4, , circles, GL_FLOAT_MAT4, [[0.0, 0.0, 125.0, -125.0],
 [0.0, 144.0, -72.0, -72.0],
 [230.0, 58.0, 58.0, 58.0],
 [0.0, 0.0, 0.0, 0.0]]
5, 5, , attrs, GL_FLOAT_VEC4, [0.0, 0.0, 0.7, 471.06]

* */
            GLES20.glUniform4fv(mColorHandle, 1, color, 0);

            GLES20.glUniform4f(mRectHandle, 28.0f, 12.0f, 28.0f, 28.0f);

            float circleMatrix[] = new float[]{
                    0.0f, 0.0f, 125.0f, -125.0f,
            0.0f, 144.0f, -72.0f, -72.0f,
            230.0f, 58.0f, 58.0f, 58.0f,
            0.0f, 0.0f, 0.0f, 0.0f};

            GLES20.glUniformMatrix4fv(mCircleHandle, 1, false, circleMatrix, 0);
            GLES20.glUniform1f(mCValueHandle, 1.1875f);
            GLES20.glUniform1f(mPowerHandle, 2.0f);
            GLES20.glUniform4f(mAttrsHandle, 0.0f, 0.0f, 0.7f, 471.06f);


            // get handle to shape's transformation matrix
            MyGLRenderer.checkGlError("glGetUniformLocation");

            // Apply the projection and view transformation
            float mvpMatrix[] = new float[]{
                    -1.5943183f, -4.140375f, 0.0f, 0.0f,
            -3.9087458f, 1.5051256f, 0.0f, 0.0f,
            0.0f, -0.0f, -3.0000002f, 500.00024f,
            0.0f, 0.0f, -1.0f, 1500.0f};

            GLES20.glUniformMatrix4fv(mMVPMatrixHandle, 1, false, mvpMatrix, 0);
            MyGLRenderer.checkGlError("glUniformMatrix4fv");

            // Draw the triangle
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, vertexCount);
            //GLES30.glDrawArraysInstanced(GLES30.GL_TRIANGLE_STRIP, 0, vertexCount,60);

        }
        GLES20.glDisable(GLES20.GL_BLEND);

    }

}
