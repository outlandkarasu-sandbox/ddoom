import std.stdio;
import std.string : toStringz;
import std.algorithm : max;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;
import derelict.assimp3.assimp;

import ddoom.sdl;
import ddoom.application : Application;

/// 共有ライブラリのロード
shared static this() {
    DerelictSDL2.load();
    DerelictGL3.load();
    DerelictASSIMP3.load();
}

enum {
    WINDOW_WIDTH = 640, /// ウィンドウの幅
    WINDOW_HEIGHT = 640, /// ウィンドウの高さ
}

/// フレームレート
enum FPS = 60.0;
enum MS_PER_FRAME = cast(uint)(1000.0 / FPS);

/// ウィンドウタイトル
enum WINDOW_TITLE = "ddoom";

/**
 *  メイン関数
 *
 *  Params:
 *      args = コマンドライン引数
 */ 
void main(string[] args) {
    // SDL初期化
    enforceSDL(SDL_Init(SDL_INIT_EVERYTHING) == 0);
    scope(exit) SDL_Quit();

    // OpenGL ダブルバッファリング有効化
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    // OpenGL 最新バージョン使用
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

    // ウィンドウ生成
    auto window = enforceSDL(SDL_CreateWindow(
            toStringz(WINDOW_TITLE),
            SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED,
            WINDOW_WIDTH,
            WINDOW_HEIGHT,
            SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN));
    scope(exit) SDL_DestroyWindow(window);

    // OpenGLコンテキストの生成
    auto context = enforceSDL(SDL_GL_CreateContext(window));
    scope(exit) SDL_GL_DeleteContext(context);

    // OpenGL3 ライブラリ再ロード
    DerelictGL3.reload();
    debug writefln("OpenGL version: %s", DerelictGL3.loadedVersion);

    // アプリケーション初期化
    Application app = new Application();
    scope(exit) app.exit();

    // メインループ
    for(bool loop = true; loop;) {
        // フレーム開始時間
        immutable beginTicks = SDL_GetTicks();
        for(SDL_Event event; SDL_PollEvent(&event);) {
            // キーボード押下で終了
            switch(event.type) {
                case SDL_QUIT:
                case SDL_KEYDOWN:
                    loop = false;
                    break;
                default:
                    break;
            }
        }

        // 描画処理
        try {
            app.drawFrame();
        } catch(Throwable t) {
            stderr.writefln("error: %s", t);
        }

        // ウィンドウバッファ切り替え
        SDL_GL_SwapWindow(window);

        // 残り時間は待機
        immutable elapse = SDL_GetTicks() - beginTicks;
        SDL_Delay((elapse < MS_PER_FRAME) ? MS_PER_FRAME - elapse : 0);
    }
}

