module ddoom.application;

import std.stdio;

import derelict.opengl3.gl3;
import gl3n.linalg;
import gl3n.math;

import ddoom.camera;
import ddoom.gl;

/**
 * DDoom アプリケーションクラス
 *
 * 生成時点でSDL・OpenGLは初期化されている。
 */
class Application {

    /// 初期化
    this() {
        // 頂点配列の確保
        glGenVertexArrays(1, &vertexArrayID_);
        glBindVertexArray(vertexArrayID_);

        // 頂点バッファの確保
        glGenBuffers(1, &vertexBuffer_);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer_);
        glBufferData(
                GL_ARRAY_BUFFER,
                VERTEX_BUFFER_DATA.length * GLfloat.sizeof,
                VERTEX_BUFFER_DATA.ptr,
                GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);

        // 頂点シェーダー・ピクセルシェーダーの生成
        programID_ = compileProgram(
                import("ddoom/test.vs"),
                import("ddoom/test.fs"));

        // 視点変換行列のIDを取得
        mvpID_ = glGetUniformLocation(programID_, "MVP");
    }

    /// フレーム描画
    void drawFrame() {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glUseProgram(programID_);

        // 視点を設定する
        Camera cam;
        cam.move(0.0f, 0.0f, -1.0f)
           .rotateX(cradians!(45.0))
           .rotateY(cradians!(45.0));

        mat4 projection = mat4.identity;
        mat4 model = mat4.identity;
        mat4 view = cam.matrix;
        mat4 mvp = model * view * projection;
        glUniformMatrix4fv(mvpID_, 1, GL_TRUE, mvp.value_ptr);

        glEnableVertexAttribArray(0);
        scope(exit) glDisableVertexAttribArray(0);

        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer_);
        scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);

        glVertexAttribPointer(
            0,
            3,
            GL_FLOAT,
            GL_FALSE,
            0,
            cast(void*)0);

        // Draw the triangle !
        glDrawArrays(GL_TRIANGLES, 0, 3);
    }

    /// アプリケーション終了
    void exit() {
        glDeleteProgram(programID_);
        glDeleteBuffers(1, &vertexBuffer_);
    }

private:

    /// 頂点データ
    static immutable GLfloat[] VERTEX_BUFFER_DATA = [
        -0.1f, -0.1f, 0.0f,
        0.1f, -0.1f, 0.0f,
        0.0f,  0.1f, 0.0f,
    ];

    /// 頂点配列ID
    GLuint vertexArrayID_;

    /// 頂点バッファ
    GLuint vertexBuffer_;

    /// シェーダープログラムID
    GLuint programID_;

    /// 視点変換行列変数のID
    GLuint mvpID_;
}

