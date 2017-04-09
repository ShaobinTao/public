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
public class Wall {

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
            "precision mediump float;\n"+
                    "varying vec4 pos;	//vertex\n"+
                    "varying vec2 vTextureCoord;//texture coord\n"+
                    "\n"+
                    "uniform sampler2D uSampler; //image\n"+
                    "\n"+
                    "varying vec4 fDimen;	// max/radius/width/height\n"+
                    "uniform vec4 paintColor;	// paintColor for current obj\n"+
                    "\n"+
                    "uniform vec4 attrs;		//order by type/mixType/alpha/rotateAngle\n"+
                    "\n"+
                    "\n"+
                    "vec2 getRoundRectSize(in float r){\n"+
                    "    return vec2(fDimen.z,fDimen.w)/2.0 - r;\n"+
                    "}\n"+
                    "\n"+
                    "float udRoundRect(in vec2 p, in float r)\n"+
                    "{\n"+
                    "	vec2 b = getRoundRectSize(r);\n"+
                    "	highp vec2 v1 = max(abs(p) - b, 0.0);\n"+
                    "    return clamp(length(v1) - r, 0.0, 1.0 );\n"+
                    "}\n"+
                    "\n"+
                    "\n"+
                    "void main(void) {\n"+
                    "//	type = attrs.x;\n"+
                    "//	radius = fDimen.y;\n"+
                    "//	alpha = attrs.z;\n"+
                    "//	rotateAngle = attrs.w;\n"+
                    "\n"+
                    "	vec4 tex;\n"+
                    "   	vec4 bg = vec4(paintColor.rgb, 1.0)*paintColor.a;\n"+
                    "    if(attrs.x==0.0){\n"+
                    "    	tex = bg;\n"+
                    "    }else{\n"+
             //       "   		tex = texture2D(uSampler, vTextureCoord);\n"+
                    "tex=vec4(1.0, 0.0, 0.0, 1.0);\n"+
                    "   		if(attrs.y==0.0)\n"+
                    "    		tex = bg*(1.-tex.a)+tex;\n"+
                    "    	else \n"+
                    "    		tex = bg*tex.a+tex * (1.0 - tex.a);	//the tex part where we can see is mixed with color, or transparent.\n"+
                    "    }\n"+
                    "    gl_FragColor = tex * attrs.z;\n"+
                    "\n"+
                    "	if(fDimen.y!=0.0){\n"+
                    "		vec4 transparent = vec4(0.0);\n"+
                    "		float ma = udRoundRect(pos.xy,fDimen.y);\n"+
                    "    	gl_FragColor = mix(gl_FragColor,transparent,ma);  //x y a => x*(1-a)+y*a\n"+
                    "	}\n"+
//                    "	gl_FragColor=vec4(1.0);\n"+
                    "}\n";


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
    private int mAttrsHandle;
    private int mMVPMatrixHandle;
    private int mTextureHandle;

    // number of coordinates per vertex in this array
    static final int COORDS_PER_VERTEX = 5;
    static float triangleCoords[] = {
            -360.0f,  -360.0f, 0.0f,0.0f,0.0f,
            -360.0f, 360.0f, 0.0f,0.0f,0.1f,
            360.0f, -360.0f, 0.0f,1.0f,0.0f,
            360.0f, 360.0f, 0.0f,1.0f,1.0f
    };
    private final int vertexCount = triangleCoords.length / COORDS_PER_VERTEX;
    private final int vertexStride = COORDS_PER_VERTEX * 4; // 4 bytes per vertex

    float color[] = { 1.0f, 1.0f, 1.0f, 1.0f };

    /**
     * Sets up the drawing object data for use in an OpenGL ES context.
     */
    public Wall() {
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
        //    mTextureHandle = GLES20.glGetAttribLocation(mProgram, "aTextureCoord");
        MyGLRenderer.checkGlError("glGetUniformLocation");
/*
﻿0, 0, , uSampler, GL_SAMPLER_2D, [0]
1, 1, , agRect, GL_FLOAT_VEC4, [720.0, 0.0, 720.0, 720.0]
2, 2, , MVPMatrix, GL_FLOAT_MAT4, [[4.1666665, 0.0, 0.0, -500.0],
 [0.0, -3.9335663, 0.0, 555.94403],
 [0.0, 0.0, -3.0000002, 500.00024],
 [0.0, 0.0, -1.0, 1500.0]]
3, 3, , attrs, GL_FLOAT_VEC4, [0.0, 0.0, 1.0, 0.0]
4, 4, , paintColor, GL_FLOAT_VEC4, [0.0, 0.0, 0.0, 0.0]

 */
        mRectHandle = GLES20.glGetUniformLocation(mProgram, "agRect");
        MyGLRenderer.checkGlError("glGetUniformLocation");

        mMVPMatrixHandle = GLES20.glGetUniformLocation(mProgram, "MVPMatrix");
        MyGLRenderer.checkGlError("glGetUniformLocation");

        mColorHandle = GLES20.glGetUniformLocation(mProgram, "paintColor");

        mAttrsHandle = GLES20.glGetUniformLocation(mProgram, "attrs");

        MyGLRenderer.checkGlError("glGetUniformLocation");

        // Enable a handle to the triangle vertices
        GLES20.glEnableVertexAttribArray(mPositionHandle);

        vertexBuffer.position(0);

        // Prepare the triangle coordinate data
        GLES20.glVertexAttribPointer(
                mPositionHandle, 3,
                GLES20.GL_FLOAT, false,
                vertexStride, vertexBuffer);
        GLES20.glDisableVertexAttribArray(mPositionHandle);

        // Enable a handle to the triangle vertices
        /*
        GLES20.glEnableVertexAttribArray(mTextureHandle);

        vertexBuffer.position(3);

        // Prepare the triangle coordinate data
        GLES20.glVertexAttribPointer(
                mTextureHandle, 2,
                GLES20.GL_FLOAT, false,
                vertexStride, vertexBuffer);
                */
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
        GLES20.glUseProgram(mProgram);
        GLES20.glEnable(GLES20.GL_BLEND);
        GLES20.glBlendFunc(GLES20.GL_ONE,GLES20.GL_ONE_MINUS_SRC_ALPHA);
//        for(int i=0;i<k;i++) {
            // Enable a handle to the triangle vertices
            GLES20.glEnableVertexAttribArray(mPositionHandle);
        vertexBuffer.position(0);

        // Prepare the triangle coordinate data
        GLES20.glVertexAttribPointer(
                mPositionHandle, 3,
                GLES20.GL_FLOAT, false,
                vertexStride, vertexBuffer);
 //           GLES20.glEnableVertexAttribArray(mTextureHandle);

            GLES20.glUniform4f(mColorHandle, 0f,0f,0f,0f);
            GLES20.glUniform4f(mRectHandle, 720.0f, 0.0f, 720.0f, 720.0f);

            GLES20.glUniform4f(mAttrsHandle, 0.0f, 0.0f, 1.0f, 0.0f);
/*
            ﻿0, 0, , uSampler, GL_SAMPLER_2D, [0]
            1, 1, , agRect, GL_FLOAT_VEC4, [720.0, 0.0, 720.0, 720.0]
            2, 2, , MVPMatrix, GL_FLOAT_MAT4, [[4.1666665, 0.0, 0.0, -500.0],
            [0.0, -3.9335663, 0.0, 555.94403],
            [0.0, 0.0, -3.0000002, 500.00024],
            [0.0, 0.0, -1.0, 1500.0]]
            3, 3, , attrs, GL_FLOAT_VEC4, [0.0, 0.0, 1.0, 0.0]
            4, 4, , paintColor, GL_FLOAT_VEC4, [0.0, 0.0, 0.0, 0.0]
*/

            // get handle to shape's transformation matrix
            MyGLRenderer.checkGlError("glGetUniformLocation");

            // Apply the projection and view transformation
            float mvpMatrix[] = new float[]{
                    4.1666665f, 0.0f, 0.0f, -500.0f,
            0.0f, -3.9335663f, 0.0f, 555.94403f,
            0.0f, 0.0f, -3.0000002f, 500.00024f,
            0.0f, 0.0f, -1.0f, 1500.0f};


            GLES20.glUniformMatrix4fv(mMVPMatrixHandle, 1, false, mvpMatrix, 0);
            MyGLRenderer.checkGlError("glUniformMatrix4fv");

            // Draw the triangle
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, vertexCount);
            //GLES30.glDrawArraysInstanced(GLES30.GL_TRIANGLE_STRIP, 0, vertexCount,60);
// 2 (big circle texture) with gradient fill the circle
        /*
        * ﻿0, 0, , uSampler, GL_SAMPLER_2D, [0]
1, 1, , agRect, GL_FLOAT_VEC4, [720.0, 360.0, 720.0, 720.0]
2, 2, , MVPMatrix, GL_FLOAT_MAT4, [[3.1372406, -3.1372406, 0.0, -1.13028065E-4],
 [-2.9617305, -2.9617305, 0.0, 1.06704814E-4],
 [0.0, 0.0, -3.0000002, 500.00024],
 [0.0, 0.0, -1.0, 1500.0]]
3, 3, , attrs, GL_FLOAT_VEC4, [1.0, 0.0, 1.0, 45.0]
4, 4, , paintColor, GL_FLOAT_VEC4, [0.0, 0.0, 0.0, 0.0]
*/
        GLES20.glUniform4f(mColorHandle, 0f,0f,0f,0f);
        GLES20.glUniform4f(mRectHandle, 720.0f, 360.0f, 720.0f, 720.0f);

        GLES20.glUniform4f(mAttrsHandle, 1.0f, 0.0f, 1.0f, 45.0f);

        GLES20.glBlendFunc(GLES20.GL_DST_ALPHA,GLES20.GL_ONE_MINUS_SRC_ALPHA);

        // get handle to shape's transformation matrix
        MyGLRenderer.checkGlError("glGetUniformLocation");

        // Apply the projection and view transformation
         mvpMatrix = new float[]{
                3.1372406f, -3.1372406f, 0.0f, 0.0f,
        -2.9617305f, -2.9617305f, 0.0f, 0.0f,
        0.0f, 0.0f, -3.0000002f, 500.00024f,
        0.0f, 0.0f, -1.0f, 1500.0f};



        GLES20.glUniformMatrix4fv(mMVPMatrixHandle, 1, false, mvpMatrix, 0);
        MyGLRenderer.checkGlError("glUniformMatrix4fv");

        // Draw the triangle
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, vertexCount);
///        }

// 3 actually draw the album cover
/*
        ﻿0, 0, , uSampler, GL_SAMPLER_2D, [0]
        1, 1, , agRect, GL_FLOAT_VEC4, [720.0, 0.0, 720.0, 720.0]
        2, 2, , MVPMatrix, GL_FLOAT_MAT4, [[2.7685187, 0.0, 0.0, 0.0],
        [0.0, -2.6136365, 0.0, -1.06704814E-4],
        [0.0, 0.0, -3.0000002, 500.00024],
        [0.0, 0.0, -1.0, 1500.0]]
        3, 3, , attrs, GL_FLOAT_VEC4, [1.0, 0.0, 1.0, 0.0]
        4, 4, , paintColor, GL_FLOAT_VEC4, [0.0, 0.0, 0.0, 0.0]
**/
        GLES20.glUniform4f(mColorHandle, 0f,0f,0f,0f);
        GLES20.glUniform4f(mRectHandle, 720.0f, 0.0f, 720.0f, 720.0f);

        GLES20.glUniform4f(mAttrsHandle, 1.0f, 0.0f, 1.0f, 0.0f);

        GLES20.glBlendFunc(GLES20.GL_ONE,GLES20.GL_ONE_MINUS_SRC_ALPHA);


        // get handle to shape's transformation matrix
        MyGLRenderer.checkGlError("glGetUniformLocation");

        // Apply the projection and view transformation
        mvpMatrix = new float[]{
                2.7685187f, 0.0f, 0.0f, 0.0f,
        0.0f, -2.6136365f, 0.0f, 0.0f,
        0.0f, 0.0f, -3.0000002f, 500.00024f,
        0.0f, 0.0f, -1.0f, 1500.0f};


        GLES20.glUniformMatrix4fv(mMVPMatrixHandle, 1, false, mvpMatrix, 0);
        MyGLRenderer.checkGlError("glUniformMatrix4fv");

        // Draw the triangle
//        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, vertexCount);

// 4
       /*﻿
       0, 0, , uSampler, GL_SAMPLER_2D, [0]
1, 1, , agRect, GL_FLOAT_VEC4, [720.0, 0.0, 720.0, 720.0]
2, 2, , MVPMatrix, GL_FLOAT_MAT4, [[2.7685187, 0.0, 0.0, 0.0],
 [0.0, -2.6136365, 0.0, -1.06704814E-4],
 [0.0, 0.0, -3.0000002, 500.00024],
 [0.0, 0.0, -1.0, 1500.0]]
3, 3, , attrs, GL_FLOAT_VEC4, [0.0, 0.0, 1.0, 0.0]
4, 4, , paintColor, GL_FLOAT_VEC4, [0.0, 0.0, 0.0, 0.0]
*/
        GLES20.glUniform4f(mColorHandle, 0f,0f,0f,0f);
        GLES20.glUniform4f(mRectHandle, 720.0f, 0.0f, 720.0f, 720.0f);

        GLES20.glUniform4f(mAttrsHandle, 0.0f, 0.0f, 1.0f, 0.0f);


        // get handle to shape's transformation matrix
        MyGLRenderer.checkGlError("glGetUniformLocation");

        // Apply the projection and view transformation
        mvpMatrix = new float[]{
                2.7685187f, 0.0f, 0.0f, 0.0f,
                0.0f, -2.6136365f, 0.0f, 0.0f,
                0.0f, 0.0f, -3.0000002f, 500.00024f,
                0.0f, 0.0f, -1.0f, 1500.0f};


        GLES20.glUniformMatrix4fv(mMVPMatrixHandle, 1, false, mvpMatrix, 0);
        MyGLRenderer.checkGlError("glUniformMatrix4fv");

        // Draw the triangle
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, vertexCount);


        GLES20.glDisable(GLES20.GL_BLEND);
    }

}
