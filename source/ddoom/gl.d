/**
 *  OpenGL関連のユーティリティモジュール
 */ 
module ddoom.gl;

import derelict.opengl3.gl3;

/// OpenGL関連例外
class GLException : Exception {
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
    }
    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line, next);
    }
}

/// シェーダーのコンパイル
GLuint compileProgram(string vsSource, string fsSource) {
    // 頂点シェーダー生成
    immutable vs = glCreateShader(GL_VERTEX_SHADER);
    scope(exit) glDeleteShader(vs);
    compileShader(vs, vsSource);

    // フラグメントシェーダー生成
    immutable fs = glCreateShader(GL_FRAGMENT_SHADER);
    scope(exit) glDeleteShader(fs);
    compileShader(fs, fsSource);

    // リンク
    immutable program = glCreateProgram();
    glAttachShader(program, vs);
    scope(exit) glDetachShader(program, vs);
    glAttachShader(program, fs);
    scope(exit) glDetachShader(program, fs);
    glLinkProgram(program);
    throwIfLinkError(program);

    return program;
}

/// シェーダーのコンパイルを行う
void compileShader(GLuint id, string source) {
    const char* sourcePtr = source.ptr;
    glShaderSource(id, 1, &sourcePtr, null);
    glCompileShader(id);
    throwIfCompileError(id);
}

/// シェーダーエラー発生時に例外を投げる
private void throwIfShaderError(alias getter, GLenum TYPE)(GLuint id) {
    GLint result = GL_FALSE;
    GLint logLength = 0;
    getter(id, TYPE, &result);
    getter(id, GL_INFO_LOG_LENGTH, &logLength);
    if(logLength > 0) {
        auto message = new GLchar[logLength];
        glGetShaderInfoLog(id, logLength, null, message.ptr);
        throw new GLException(message.idup);
    }
}

/// コンパイルエラー時に例外発生
private alias throwIfShaderError!(glGetShaderiv, GL_COMPILE_STATUS)
    throwIfCompileError;

/// リンクエラー時に例外発生
private alias throwIfShaderError!(glGetProgramiv, GL_LINK_STATUS)
    throwIfLinkError;

