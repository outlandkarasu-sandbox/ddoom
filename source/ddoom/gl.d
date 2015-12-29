/**
 *  OpenGL関連のユーティリティモジュール
 */ 
module ddoom.gl;

import std.format : format;
import std.stdio : writefln;

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

/// OpenGLのエラーチェックを行う
void checkGLError(string file = __FILE__, size_t line = __LINE__) {
    GLenum[] errors;
    for(GLenum error; (error = glGetError()) != GL_NO_ERROR;) {
        errors ~= error;
    }

    if(errors.length > 0) {
        throw new GLException(format("%s", errors), file, line);
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
private void throwIfShaderError(alias getter, alias getLog, GLenum TYPE)(GLuint id) {
    GLint result = GL_FALSE;
    getter(id, TYPE, &result);
    if(result != GL_TRUE) {
        GLint logLength = 0;
        getter(id, GL_INFO_LOG_LENGTH, &logLength);
        auto message = new GLchar[logLength];

        GLsizei size;
        getLog(id, logLength, &size, message.ptr);
        throw new GLException(message[0 .. size].idup);
    }
}

/// コンパイルエラー時に例外発生
private alias throwIfShaderError!(glGetShaderiv, glGetShaderInfoLog, GL_COMPILE_STATUS)
    throwIfCompileError;

/// リンクエラー時に例外発生
private alias throwIfShaderError!(glGetProgramiv, glGetProgramInfoLog, GL_LINK_STATUS)
    throwIfLinkError;

