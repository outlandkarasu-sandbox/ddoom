module ddoom.gpu;

import std.algorithm : fill;
import std.stdio : writefln;
import std.experimental.allocator : theAllocator, makeArray, dispose;

import derelict.opengl3.gl3;
import gl3n.linalg;

import ddoom.asset : Mesh, Bone;
import ddoom.gl;

/// GPUに転送されたメッシュ
class GPUMesh {

    /// GPUと結びつける
    this(const(Mesh) mesh) {
        // 頂点配列の確保
        glGenVertexArrays(1, &vertexArrayID_);

        // バッファの初期化
        initializeVerticesBuffer(mesh.vertices);
        initializeNormalBuffer(mesh.normals);
        initializeBoneBuffer(mesh.bones, mesh.vertices.length);

        // 各要素バッファの初期化
        foreach(e; mesh.faces.byKeyValue) {
            // 1要素当たりの頂点数
            immutable vcount = e.key;

            // 要素数
            immutable size = cast(uint) e.value.length;

            // 要素バッファの生成
            GLuint id;
            glGenBuffers(1, &id);

            // エラー発生時は破棄
            scope(failure) glDeleteBuffers(1, &id);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id);
            scope(exit) glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

            // 要素バッファにデータを転送する
            glBufferData(
                GL_ELEMENT_ARRAY_BUFFER,
                size * uint.sizeof,
                e.value.ptr,
                GL_STATIC_DRAW);

            // ID登録
            elementArrays_[e.key] = ElementArrayInfo(id, size);
        }

        // マテリアル
        auto c = mesh.material.diffuse;
        diffuse_ = vec3(c.x, c.y, c.z);
        c = mesh.material.ambient;
        ambient_ = vec3(c.x, c.y, c.z);
        c = mesh.material.specular;
        specular_ = vec3(c.x, c.y, c.z);
    }

    /// 解放処理
    ~this() nothrow @nogc {
        release();
    }

    /// GPUとの結び付けを解除する
    void release() nothrow @nogc {
        // 頂点要素配列の解放
        foreach(ref info; elementArrays_.byValue) {
            glDeleteBuffers(1, &info.id);
            info.id = 0;
            info.size = 0;
        }
        elementArrays_ = elementArrays_.init;

        // 頂点バッファの解放
        glDeleteBuffers(1, &vertexBufferID_);
        vertexBufferID_ = 0;

        // 法線バッファの解放
        glDeleteBuffers(1, &normalBufferID_);
        normalBufferID_ = 0;

        // ボーンバッファの解放
        glDeleteBuffers(1, &boneBufferID_);
        boneBufferID_ = 0;

        // 頂点配列の解放
        glDeleteVertexArrays(1, &vertexArrayID_);
        vertexArrayID_ = 0;
    }

    /// 描画
    void draw(ref GPUProgram.Context context) const @nogc nothrow {
        // マテリアルの設定
        context.diffuse = diffuse_;
        context.ambient = ambient_;
        context.specular = specular_;
        context.setUpUniform();

        // 頂点配列の選択
        glBindVertexArray(vertexArrayID_);
        scope(exit) glBindVertexArray(0);

        // 位置の有効化
        enable(VertexAttribute.Position, vertexBufferID_, 3, GL_FLOAT);
        scope(exit) glDisableVertexAttribArray(VertexAttribute.Position);

        // 法線の有効化
        enable(VertexAttribute.Normal, normalBufferID_, 3, GL_FLOAT);
        scope(exit) glDisableVertexAttribArray(VertexAttribute.Normal);

        // ボーンIDの有効化
        enable(VertexAttribute.BoneIDs, boneBufferID_, BoneCount, GL_UNSIGNED_INT, BoneInfo.sizeof);
        scope(exit) glDisableVertexAttribArray(VertexAttribute.BoneIDs);

        // ボーン重みの有効化
        enable(VertexAttribute.BoneWeights, boneBufferID_, BoneCount, GL_FLOAT, BoneInfo.sizeof, BoneInfo.weights.offsetof);
        scope(exit) glDisableVertexAttribArray(VertexAttribute.BoneWeights);

        // 要素バッファの描画
        foreach(e; elementArrays_.byKeyValue) {
            immutable vcount = e.key;
            immutable type = toGLType(vcount);
            immutable info = e.value;

            // 描画対象の要素バッファの結び付け
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, info.id);
            scope(exit) glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

            // 要素バッファを描画する
            glDrawElements(type, info.size, GL_UNSIGNED_INT, null);
        }
    }

private:

    /// 要素配列の情報
    struct ElementArrayInfo {
        GLuint id;
        uint size;
    }

    /// 1頂点当たりのボーン数
    enum BoneCount = 4;

    /// ボーン情報
    struct BoneInfo {
        uint[BoneCount] ids;
        float[BoneCount] weights = [0.0f, 0.0f, 0.0f, 0.0f];
    }

    /// 頂点属性
    enum VertexAttribute : GLuint {
        Position,    /// 位置
        Normal,      /// 法線
        BoneIDs,     /// ボーンID
        BoneWeights, /// ボーン重み
    }

    /// 頂点数から描画タイプを判別する
    static GLenum toGLType(uint vcount) @safe nothrow pure @nogc {
        switch(vcount) {
        case 3: return GL_TRIANGLES;
        case 2: return GL_LINES;
        default: case 1: return GL_POINTS;
        }
    }

    /// 頂点バッファの初期化
    void initializeVerticesBuffer(const(vec3)[] vertices)
    in {
        assert(vertexBufferID_ == 0);
    } body {
        // 頂点バッファの確保
        glGenBuffers(1, &vertexBufferID_);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID_);
        scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);

        // 頂点バッファにデータを転送する
        glBufferData(
            GL_ARRAY_BUFFER,
            vertices.length * vec3.sizeof,
            vertices.ptr,
            GL_STATIC_DRAW);
    }

    /// 法線バッファの初期化
    void initializeNormalBuffer(const(vec3)[] normals)
    in {
        assert(normalBufferID_ == 0);
    } body {
        // 法線バッファの確保
        glGenBuffers(1, &normalBufferID_);
        glBindBuffer(GL_ARRAY_BUFFER, normalBufferID_);
        scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);

        // 法線バッファにデータを転送する
        glBufferData(
            GL_ARRAY_BUFFER,
            normals.length * vec3.sizeof,
            normals.ptr,
            GL_STATIC_DRAW);
    }

    /// ボーンバッファの初期化
    void initializeBoneBuffer(const(Bone)[] bones, size_t vertices)
    in {
        assert(boneBufferID_ == 0);
    } body {
        // ボーン情報配列の確保
        auto boneInfos = theAllocator.makeArray!BoneInfo(vertices);
        scope(exit) theAllocator.dispose(boneInfos);

        // ボーンの重みの更新
        static void updateBoneWeight(
                ref BoneInfo info,
                uint boneId,
                ref const Bone.Weight w)
                @safe @nogc nothrow {
            // 重みが現在のボーンより小さいものを見つけたら、
            // 現在の重みで置き換える
            foreach(i, oldWeight; info.weights) {
                if(oldWeight < w.weight) {
                    info.ids[i] = boneId;
                    info.weights[i] = w.weight;
                    break;
                }
            }
        }

        // ボーン情報の生成
        foreach(i, b; bones) {
            foreach(w; b.weights) {
                updateBoneWeight(boneInfos[w.vertexId], cast(uint) i, w);
            }
        }

        // ボーンバッファの確保
        glGenBuffers(1, &boneBufferID_);
        glBindBuffer(GL_ARRAY_BUFFER, boneBufferID_);
        scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);

        // 法線バッファにデータを転送する
        glBufferData(
            GL_ARRAY_BUFFER,
            BoneInfo.sizeof * boneInfos.length,
            boneInfos.ptr,
            GL_STATIC_DRAW);
    }

    /// 頂点属性の有効化
    void enable(
            VertexAttribute attribute,
            GLuint bufferID,
            GLuint size,
            GLenum type,
            GLuint stride = 0,
            GLuint offset = 0) const nothrow @nogc {
        glEnableVertexAttribArray(attribute);
        glBindBuffer(GL_ARRAY_BUFFER, bufferID);
        scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);
        glVertexAttribPointer(
                attribute, size, type, GL_FALSE, stride, cast(const(GLvoid*)) offset);
    }

    /// 頂点配列ID
    GLuint vertexArrayID_;

    /// 頂点バッファID
    GLuint vertexBufferID_;

    /// 法線バッファID
    GLuint normalBufferID_;

    /// ボーンバッファID
    GLuint boneBufferID_;

    /// インデックスバッファID
    ElementArrayInfo[uint] elementArrays_;

    /// 表面色
    vec3 diffuse_;

    /// 環境色
    vec3 ambient_;

    /// ハイライト色
    vec3 specular_;
}

/// GPU上のシェーダープログラムのクラス
class GPUProgram {

    /// プログラム使用時のコンテキスト情報
    struct Context {
        @property nothrow @nogc {

            /// モデル位置の設定
            void model(mat4 m) {model_ = m;}

            /// 視点位置の設定
            void view(mat4 v) {view_ = v;}

            /// 投影変換行列の設定
            void projection(mat4 v) {projection_ = v;}

            /// 光源位置の設定
            void lightPosition(vec3 pos) {lightPosition_ = pos;}

            /// 拡散光の色
            void diffuse(vec3 color) {diffuse_ = color;}

            /// 環境光の色
            void ambient(vec3 color) {ambient_ = color;}

            /// ハイライトの色
            void specular(vec3 color) {specular_ = color;}

            /// ボーン設定
            void bones(const(mat4)[] b) {bones_ = b;}

            /// Uniform変数の設定
            void setUpUniform() @nogc nothrow {
                auto pg = program_;

                // モデル行列
                glUniformMatrix4fv(pg.mID_, 1, GL_TRUE, model_.value_ptr);

                // ビュー行列
                glUniformMatrix4fv(pg.vID_, 1, GL_TRUE, view_.value_ptr);

                // 光源位置
                glUniform3fv(pg.lightPositionID_, 1, lightPosition_.value_ptr);

                // 視点変換行列
                immutable mvp = projection_ * view_ * model_;
                glUniformMatrix4fv(pg.mvpID_, 1, GL_TRUE, mvp.value_ptr);

                // 表面色の設定
                glUniform3fv(pg.diffuseID_, 1, diffuse_.value_ptr);
                glUniform3fv(pg.ambientID_, 1, ambient_.value_ptr);
                glUniform3fv(pg.specularID_, 1, specular_.value_ptr);

                // ボーン
                glUniformMatrix4fv(
                        pg.bonesID_,
                        cast(uint) bones_.length,
                        GL_TRUE,
                        cast(const(GLfloat)*)bones_.ptr);
            }
        }

    private:
        /// 新規生成禁止
        this(const(GPUProgram) program) @safe nothrow pure @nogc
        in {
            assert(program !is null);
        } body {
            program_ = program;
        }

        mat4 view_;
        mat4 model_;
        mat4 projection_;
        vec3 diffuse_;
        vec3 ambient_;
        vec3 specular_;
        vec3 lightPosition_;
        const(mat4)[] bones_;
        const(GPUProgram) program_;
    }

    /**
     *  Params:
     *      vertexShader = 頂点シェーダーのソース
     *      fragmentShader = ピクセルシェーダーのソース
     */
    this(string vertexShader, string fragmentShader) {
        // 頂点シェーダー・ピクセルシェーダーの生成
        programID_ = compileProgram(vertexShader, fragmentShader);

        // 変数のIDを取得
        mvpID_ = glGetUniformLocation(programID_, "MVP");
        mID_ = glGetUniformLocation(programID_, "M");
        vID_ = glGetUniformLocation(programID_, "V");
        mvID_ = glGetUniformLocation(programID_, "MV");
        lightPositionID_ = glGetUniformLocation(programID_, "LightPosition_worldspace");
        diffuseID_ = glGetUniformLocation(programID_, "Diffuse");
        ambientID_ = glGetUniformLocation(programID_, "Ambient");
        specularID_ = glGetUniformLocation(programID_, "Specular");
        bonesID_ = glGetUniformLocation(programID_, "Bones");
    }

    /// 破棄時の処理
    ~this() nothrow @nogc {
        release();
    }

    /// プログラムの解放
    void release() nothrow @nogc {
        glDeleteProgram(programID_);
        programID_ = 0;
        mvpID_ = 0;
        vID_ = 0;
        mID_ = 0;
        mvID_ = 0;
        lightPositionID_ = 0;
        diffuseID_ = 0;
        ambientID_ = 0;
        specularID_ = 0;
        bonesID_ = 0;
    }

    /// プログラムを使用し、処理を行う
    void duringUse(void delegate(ref Context) @nogc dg) const @nogc {
        // 使用プログラム設定
        glUseProgram(programID_);
        scope(exit) glUseProgram(0);

        // 使用中の処理実行
        auto ctx = Context(this);
        dg(ctx);
    }

private:

    /// シェーダープログラムID
    GLuint programID_;

    /// 視点変換行列変数のID
    GLuint mvpID_;

    /// ビュー行列変数のID
    GLuint vID_;

    /// モデル行列変数のID
    GLuint mID_;

    /// モデルビュー行列変数のID
    GLuint mvID_;

    /// 光源位置のID
    GLuint lightPositionID_;

    /// 表面色変数のID
    GLuint diffuseID_;

    /// 環境色変数のID
    GLuint ambientID_;

    /// ハイライト色変数のID
    GLuint specularID_;

    /// ボーン変数のID
    GLuint bonesID_;
}

