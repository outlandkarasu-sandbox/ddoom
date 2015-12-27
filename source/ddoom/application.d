module ddoom.application;

import std.stdio;
import std.algorithm : map, each;

import derelict.sdl2.sdl;
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
        scope sceneAsset = new SceneAsset("asset/cube.obj");
        auto scene = sceneAsset.createScene(); 
        if(scene.root !is null) {
            meshes_ = scene.root.meshes
                .map!(m => new GPUMesh(m))
                .array;
        }

        // 視点を設定する
        camera_.move(0.0f, 0.0f, 5.0f).perspective(2.0f, 2.0f, 45.0f, 0.1f, 100.0f);
    }

    /// キーダウン時の処理
    void onKeyDown(int keyCode) {
        immutable DISTANCE = 0.05f;
        immutable ANGLE = 0.01f;
        switch(keyCode) {
        case SDL_SCANCODE_W:
            camera_.move(0.0f, 0.0f, -DISTANCE);
            break;
        case SDL_SCANCODE_S:
            camera_.move(0.0f, 0.0f, DISTANCE);
            break;
        case SDL_SCANCODE_A:
            camera_.move(-DISTANCE, 0.0f, 0.0f);
            break;
        case SDL_SCANCODE_D:
            camera_.move(+DISTANCE, 0.0f, 0.0f);
            break;
        case SDL_SCANCODE_Q:
            camera_.move(0.0f, DISTANCE, 0.0f);
            break;
        case SDL_SCANCODE_E:
            camera_.move(0.0f, -DISTANCE, 0.0f);
            break;
        case SDL_SCANCODE_DOWN:
            camera_.rotateX(ANGLE);
            break;
        case SDL_SCANCODE_UP:
            camera_.rotateX(-ANGLE);
            break;
        case SDL_SCANCODE_LEFT:
            camera_.rotateY(-ANGLE);
            break;
        case SDL_SCANCODE_RIGHT:
            camera_.rotateY(ANGLE);
            break;
        default:
            break;
        }
    }

    /// フレーム描画
    void drawFrame() {
        // 隠面消去を有効にする
        glEnable(GL_DEPTH_TEST);
        scope(exit) glDisable(GL_DEPTH_TEST);
        glDepthFunc(GL_LESS);

        // ポリゴン片面のみ描画
        glEnable(GL_CULL_FACE);
        scope(exit) glDisable(GL_CULL_FACE);

        // 画面クリア
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // 使用プログラム設定
        glUseProgram(programID_);

        // 視点変換
        mat4 model = mat4.identity;
        mat4 mvp = camera_.matrix(model);
        glUniformMatrix4fv(mvpID_, 1, GL_TRUE, mvp.value_ptr);

        // 全メッシュの描画
        meshes_.each!(m => m.draw(diffuseID_));
    }

    /// アプリケーション終了
    void exit() {
        meshes_.each!("a.release()");
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
    GPUMesh[] meshes_;

    /// カメラ
    Camera camera_;
}

