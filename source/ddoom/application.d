module ddoom.application;

import std.stdio;

import derelict.opengl3.gl3;
import gl3n.linalg;
import gl3n.math;

import ddoom.asset;
import ddoom.assimp;
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

        // 頂点シェーダー・ピクセルシェーダーの生成
        programID_ = compileProgram(
                import("ddoom/test.vs"),
                import("ddoom/test.fs"));

        // 視点変換行列のIDを取得
        mvpID_ = glGetUniformLocation(programID_, "MVP");

        // シーンの読み込み
        scope sceneAsset = new SceneAsset("asset/cube.blend");
        auto scene = sceneAsset.createScene();

        if(scene.root !is null && scene.root.meshes.length > 0) {
            mesh_ = new GPUMesh(scene.root.meshes[0]);
        }
    }

    /// フレーム描画
    void drawFrame() {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glUseProgram(programID_);

        // 視点を設定する
        Camera cam;
        cam.move(-5.0f, 1.0f, 5.0f)
           .rotateX(cradians!(0.0))
           .rotateY(cradians!(45.0))
           .rotateZ(cradians!(0.0))
           .perspective(2.0f, 2.0f, 45.0f, 0.1f, 100.0f);

        mat4 model = mat4.identity;
        mat4 mvp = cam.matrix(model);
        glUniformMatrix4fv(mvpID_, 1, GL_TRUE, mvp.value_ptr);

        if(mesh_ !is null) {
            mesh_.draw();
        }
    }

    /// アプリケーション終了
    void exit() {
        if(mesh_ !is null) {
            mesh_.release();
        }
        glDeleteProgram(programID_);
    }

private:

    /// シェーダープログラムID
    GLuint programID_;

    /// 視点変換行列変数のID
    GLuint mvpID_;

    /// メッシュオブジェクト
    GPUMesh mesh_;
}

