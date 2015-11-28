import std.stdio;
import std.string : toStringz;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;
import derelict.assimp3.assimp;

import ddoom.sdl;

/// 共有ライブラリのロード
shared static this() {
    DerelictSDL2.load();
    DerelictGL3.load();
    DerelictASSIMP3.load();
}

enum {
    WINDOW_WIDTH = 1024, /// ウィンドウの幅
    WINDOW_HEIGHT = 768, /// ウィンドウの高さ
}

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

    // メインループ
    for(bool loop = true; loop;) {
        for(SDL_Event event; SDL_PollEvent(&event);) {
            // キーボード押下で終了
            switch(event.type) {
                case SDL_KEYDOWN:
                    loop = false;
                    break;
                default:
                    break;
            }
        }
    }
}

