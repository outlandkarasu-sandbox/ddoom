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

        // 変数のIDを取得
        mvpID_ = glGetUniformLocation(programID_, "MVP");
        diffuseID_ = glGetUniformLocation(programID_, "diffuse");

        // シーンの読み込み
        scope sceneAsset = new SceneAsset("asset/cube.blend");
        auto scene = sceneAsset.createScene();

        if(scene.root !is null && scene.root.meshes.length > 0) {
            mesh_ = new GPUMesh(scene.root.meshes[0]);
        }

        // 視点を設定する
        camera_.move(-5.0f, 2.0f, 5.0f)
           .rotateX(cradians!(20.0))
           .rotateY(cradians!(42.5))
           .rotateZ(cradians!(12.5))
           .perspective(2.0f, 2.0f, 45.0f, 0.1f, 100.0f);
    }

    /// フレーム描画
    void drawFrame() {
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LESS);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glUseProgram(programID_);

        mat4 model = mat4.identity;
        mat4 mvp = camera_.matrix(model);
        glUniformMatrix4fv(mvpID_, 1, GL_TRUE, mvp.value_ptr);

        if(mesh_ !is null) {
            mesh_.draw(diffuseID_);
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

    /// 表面色変数のID
    GLuint diffuseID_;

    /// メッシュオブジェクト
    GPUMesh mesh_;

    /// カメラ
    Camera camera_;
}

