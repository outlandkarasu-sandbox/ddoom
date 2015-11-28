import std.stdio;

import derelict.sdl2.sdl;
import derelict.assimp3.assimp;

/// 共有ライブラリのロード
shared static this() {
    DerelictSDL2.load();
    DerelictASSIMP3.load();
}

/**
 *  メイン関数
 *
 *  Params:
 *      args = コマンドライン引数
 */ 
void main(string[] args) {
}

