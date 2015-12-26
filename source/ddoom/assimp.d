/**
 *  ASSIMP関連のユーティリティモジュール
 */ 
module ddoom.assimp;

import std.string : fromStringz;
import std.format : format;

import derelict.assimp3.assimp;

/// ASSIMP関連例外
class AssetException : Exception {
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
    }
    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line, next);
    }
}

/// ASSIMPエラーチェック
T enforceAsset(T)(
        T value,
        lazy const(char)[] msg = null,
        string file = __FILE__,
        size_t line = __LINE__)
        if (is(typeof((){if(!value){}}))) {
    if(!value) {
        auto errorMessage = format("%s : %s", fromStringz(aiGetErrorString()), msg);
        throw new SDLException(errorMessage, file, line);
    }
    return value;
}

