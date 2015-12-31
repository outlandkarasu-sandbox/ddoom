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
import ddoom.gpu;

/**
 * DDoom アプリケーションクラス
 *
 * 生成時点でSDL・OpenGLは初期化されている。
 */
class Application {

    /// 初期化
    this() {
        // シェーダーの生成
        program_ = new GPUProgram(
                import("ddoom/basic.vs"), import("ddoom/basic.fs"));

        // シーンの読み込み
        scope sceneAsset = new SceneAsset("asset/dman.fbx");
        auto scene = sceneAsset.createScene(); 
        if(scene.root !is null) {
            meshes_ = scene.root.meshes
                .map!(m => new GPUMesh(m))
                .array;
        }

        // 視点を設定する
        camera_.move(0.0f, 0.0f, 5.0f)
            .perspective(2.0f, 2.0f, 45.0f, 0.1f, 100.0f);
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
    void drawFrame() @nogc {
        // 終了時にフラッシュ
        scope(exit) glFlush();

        // 隠面消去を有効にする
        glEnable(GL_DEPTH_TEST);
        scope(exit) glDisable(GL_DEPTH_TEST);
        glDepthFunc(GL_LESS);

        // ポリゴン片面のみ描画
        glEnable(GL_CULL_FACE);
        scope(exit) glDisable(GL_CULL_FACE);

        // 画面クリア
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // プログラムを使用して処理を行う
        program_.duringUse(&drawMeshes);
    }

    /// アプリケーション終了
    void exit() {
        meshes_.each!(m => m.release());
        program_.release();
    }

private:

    /// メッシュの描画
    void drawMeshes(ref GPUProgram.Context context) const @nogc {
        // 視点の設定
        context.view = camera_.view;
    
        // 投影変換行列の取得
        context.projection = camera_.projection;

        // 光源の設定
        context.lightPosition = vec3(5.0f, 10.0f, 5.0f);
    
        // 全メッシュの描画
        foreach(i, m; meshes_) {
            // モデル変換行列の設定
            context.model = mat4.identity;

            // 描画処理
            m.draw(context);
        }
    }

    /// シェーダープログラム
    GPUProgram program_;

    /// メッシュオブジェクト
    GPUMesh[] meshes_;

    /// カメラ
    Camera camera_;
}

