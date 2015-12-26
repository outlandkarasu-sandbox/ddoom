/**
 *  アセット関連のモジュール
 */
module ddoom.asset;

import gl3n.linalg;

@safe:

/// シーン
class Scene {

    /// ルートノードを指定して生成する
    this(const(Node) root) {
        root_ = root;
    }

    @property const pure nothrow {

        /// ルートノードを取得する
        const(Node) root() {return root_;}
    }

private:

    /// ルートノード
    const(Node) root_;
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
            ref const(mat4) transformation) {
        meshes_ = meshes;
        children_ = children;
        transformation_ = transformation;
    }

    @property const pure nothrow {

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
     */
    this(string name,
            const(vec3)[] vertices,
            const(uint[][uint]) faces) {
        name_ = name;
        vertices_ = vertices;
        faces_ = faces;
    }

    @property const pure nothrow {

        /// 頂点配列を返す
        const(vec3)[] vertices() {return vertices_;}

        /// 面配列を返す
        const(uint[][uint]) faces() {return faces_;}
    }

private:

    /// メッシュ名
    string name_;

    /// 頂点配列
    const(vec3)[] vertices_;

    /// 面配列
    const(uint[][uint]) faces_;
}

