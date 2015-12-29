/**
 *  アセット関連のモジュール
 */
module ddoom.asset;

import std.stdio : writefln;

import derelict.opengl3.gl3;
import gl3n.linalg;

import ddoom.gl;

/// シーン
class Scene {

    /**
     *  Params:
     *      root = ルートノード
     */
    this(const(Node) root) @safe pure nothrow @nogc {
        root_ = root;
    }

    @property @safe const pure nothrow @nogc {

        /// ルートノードを取得する
        const(Node) root() {return root_;}
    }

private:

    /// ルートノード
    const(Node) root_;
}

/// 描画色などのマテリアル
class Material {

    /// 色情報
    alias vec4 Color;

    /// 値を指定して生成する
    this(string name,
            Color diffuse,
            Color specular,
            Color ambient) {
        name_ = name;
        diffuse_ = diffuse;
        specular_ = specular;
        ambient_ = ambient;
    }

    @property @safe const pure nothrow @nogc {

        /// マテリアル名を返す
        string name() {return name_;}

        /// 表面色を返す
        Color diffuse() {return diffuse_;}

        /// ハイライト色を返す
        Color specular() {return specular_;}

        /// 環境色を返す
        Color ambient() {return ambient_;}
    }

private:

    /// マテリアル名
    string name_;

    /// 表面色
    Color diffuse_;

    /// ハイライト
    Color specular_;

    /// 環境色
    Color ambient_;
}

/// ノード
class Node {

    /**
     *  Params:
     *      name = ノード名
     *      meshes = メッシュ配列
     *      children = 子ノード配列
     *      transformation = 座標変換
     *      parent = 親ノード
     */
    this(string name,
            const(Mesh)[] meshes,
            const(Node)[] children,
            ref const(mat4) transformation) @safe pure nothrow @nogc {
        meshes_ = meshes;
        children_ = children;
        transformation_ = transformation;
    }

    @property @safe const pure nothrow @nogc {

        /// ノード名を返す
        string name() {return name_;}

        /// メッシュを取得する
        const(Mesh)[] meshes() {return meshes_;}

        /// 子ノードを取得する
        const(Node)[] children() {return children_;}

        /// 座標変換行列を取得する
        const(mat4) transformation() {return transformation_;}
    }

private:

    /// ノード名
    string name_;

    /// メッシュ配列
    const(Mesh)[] meshes_;

    /// 子ノード
    const(Node)[] children_;

    /// 座標変換行列
    const(mat4) transformation_;
}

/// メッシュ
class Mesh {

    /**
     *  Params:
     *      name = メッシュ名
     *      vertices = 頂点配列
     *      faces = 面配列
     *      material = マテリアル
     */
    this(string name,
            const(vec3)[] vertices,
            const(vec3)[] normals,
            const(uint[][uint]) faces,
            const(Material) material) @safe pure nothrow @nogc {
        name_ = name;
        vertices_ = vertices;
        normals_ = normals;
        faces_ = faces;
        material_ = material;
    }

    @property @safe const pure nothrow @nogc {

        /// 頂点配列を返す
        const(vec3)[] vertices() {return vertices_;}

        /// 法線配列を返す
        const(vec3)[] normals() {return normals_;}

        /// 面配列を返す
        const(uint[][uint]) faces() {return faces_;}

        /// マテリアル
        const(Material) material() {return material_;}
    }

private:

    /// メッシュ名
    string name_;

    /// 頂点配列
    const(vec3)[] vertices_;

    /// 法線配列
    const(vec3)[] normals_;

    /// 面配列
    const(uint[][uint]) faces_;

    /// マテリアル
    const(Material) material_;
}

/// GPUに転送されたメッシュ
class GPUMesh {

    /// GPUと結びつける
    this(const(Mesh) mesh) {
        // 頂点配列の確保
        glGenVertexArrays(1, &vertexArrayID_);

        // バッファの初期化
        initializeVerticesBuffer(mesh.vertices);
        initializeNormalBuffer(mesh.normals);

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

        // 頂点配列の解放
        glDeleteVertexArrays(1, &vertexArrayID_);
        vertexArrayID_ = 0;
    }

    /// 描画
    void draw(GLuint diffuseID, GLuint ambientID) const {
        // 表面色の設定
        glUniform3fv(diffuseID, 1, diffuse_.value_ptr);
        glUniform3fv(ambientID, 1, ambient_.value_ptr);

        // 頂点配列の選択
        glBindVertexArray(vertexArrayID_);
        scope(exit) glBindVertexArray(0);

        // 頂点属性の有効化
        enableVertexAttribute(VertexAttribute.Position, vertexBufferID_);
        scope(exit) glDisableVertexAttribArray(VertexAttribute.Position);

        // 法線属性の有効化
        enableVertexAttribute(VertexAttribute.Normal, normalBufferID_);
        scope(exit) glDisableVertexAttribArray(VertexAttribute.Normal);

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

    /// 頂点属性
    enum VertexAttribute : GLuint {
        Position, /// 位置
        Normal    /// 法線
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
    void initializeVerticesBuffer(const(vec3)[] vertices) {
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
    void initializeNormalBuffer(const(vec3)[] normals) {
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

    /// 頂点属性の有効化
    void enableVertexAttribute(VertexAttribute attribute, GLuint bufferID) const {
        glEnableVertexAttribArray(attribute);
        glBindBuffer(GL_ARRAY_BUFFER, bufferID);
        scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);
        glVertexAttribPointer(attribute, 3, GL_FLOAT, GL_FALSE, 0, null);
    }

    /// 頂点配列ID
    GLuint vertexArrayID_;

    /// 頂点バッファID
    GLuint vertexBufferID_;

    /// 法線バッファID
    GLuint normalBufferID_;

    /// インデックスバッファID
    ElementArrayInfo[uint] elementArrays_;

    /// 表面色
    vec3 diffuse_;

    /// 環境色
    vec3 ambient_;
}

