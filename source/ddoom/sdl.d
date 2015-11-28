/**
 *  SDL関連のユーティリティモジュール
 */ 
module ddoom.sdl;

import std.string : fromStringz;
import std.format : format;

import derelict.sdl2.sdl;

/// SDL関連例外
class SDLException : Exception {
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
    }
    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line, next);
    }
}

/// SDLエラーチェック
T enforceSDL(T)(
        T value,
        lazy const(char)[] msg = null,
        string file = __FILE__,
        size_t line = __LINE__)
        if (is(typeof((){if(!value){}}))) {
    if(!value) {
        auto errorMessage = format("%s : %s", fromStringz(SDL_GetError()), msg);
        throw new SDLException(errorMessage, file, line);
    }
    return value;
}

