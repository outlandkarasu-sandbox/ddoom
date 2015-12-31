/**
 *  アセット関連のモジュール
 */
module ddoom.asset;

import std.stdio : writefln;

import gl3n.linalg : vec3, vec4, mat4, quat;

/// シーン
class Scene {

    /**
     *  Params:
     *      root = ルートノード
     *      animations = アニメーション
     */
    this(const(Node) root,
            const(Animation)[] animations) @safe pure nothrow @nogc {
        root_ = root;
        animations_ = animations;
    }

    @property @safe const pure nothrow @nogc {

        /// ルートノードを取得する
        const(Node) root() {return root_;}

        /// アニメーションを取得する
        const(Animation)[] animations() {return animations_;}
    }

private:

    /// ルートノード
    const(Node) root_;

    /// アニメーション
    const(Animation)[] animations_;
}

/// ノードのアニメーション
class NodeAnimation {

    /// キーフレーム構造体
    struct Key(T) {
        double time;
        T value;
    }

    alias Key!vec3 VectorKey;
    alias Key!quat QuaternionKey;

    /**
     *  Params:
     *      nodeName = 対象ノード名
     *      positionKeys = 位置のキーフレーム
     *      rotateKeys = 回転のキーフレーム
     *      scalingKeys = スケーリングのキーフレーム
     */
    this(string nodeName,
            const(VectorKey)[] positionKeys,
            const(QuaternionKey)[] rotationKeys,
            const(VectorKey)[] scalingKeys) {
        nodeName_ = nodeName;
        positionKeys_ = positionKeys;
        rotationKeys_ = rotationKeys;
        scalingKeys_ = scalingKeys;
    }

    @property @safe const pure nothrow @nogc {

        /// 対象ノード名
        string nodeName() {return nodeName_;}

        /// 位置のキーフレーム
        const(VectorKey)[] positionKeys() {return positionKeys_;}

        /// 回転のキーフレーム
        const(QuaternionKey)[] rotationKeys() {return rotationKeys_;}

        /// スケーリングのキーフレーム
        const(VectorKey)[] scalingKeys() {return scalingKeys_;}
    }

private:

    /// 対象ノード名
    string nodeName_;

    /// 位置のキーフレーム
    const(VectorKey)[] positionKeys_;

    /// 回転のキーフレーム
    const(QuaternionKey)[] rotationKeys_;

    /// スケールのキーフレーム
    const(VectorKey)[] scalingKeys_;
}

/// アニメーション
class Animation {

    /**
     *  Params:
     *      name = アニメーション名
     *      duration = アニメーションの長さ
     *      ticksPerSecond = 秒間フレーム数
     *      channels = 各ノードのアニメーション
     */
    this(string name,
            double duration,
            double ticksPerSecond,
            const(NodeAnimation)[] channels) {
        name_ = name;
        duration_ = duration;
        ticksPerSecond_ = ticksPerSecond;
        channels_ = channels;
    }

    @property @safe const pure nothrow @nogc {

        /// 名前を返す
        string name() {return name_;}

        /// アニメーションの長さを返す
        double duration() {return duration_;}

        /// 秒間フレーム数を返す
        double ticksPerSecond() {return ticksPerSecond_;}
    
        /// 各ノードのアニメーションを返す
        const(NodeAnimation)[] channels() {return channels_;}
    }

private:

    /// 名前
    string name_;

    /// アニメーションの長さ
    double duration_;

    /// 秒間フレーム数
    double ticksPerSecond_;

    /// 各ノードのアニメーション
    const(NodeAnimation)[] channels_;
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

/// ボーン
class Bone {

    /// 重み付け
    struct Weight {
        uint vertexId;
        float weight;
    }

    /**
     *  Params:
     *      name = ボーン名
     *      offset = オフセット行列
     *      weights = 重み付け
     */
    this(string name, ref const mat4 offset, const(Weight)[] weights) {
        name_ = name;
        offset_ = offset;
        weights_ = weights_;
    }

    @property @safe const pure nothrow @nogc {

        /// ボーン名
        string name() {return name_;}

        /// オフセット行列
        const(mat4) offset() {return offset_;}

        /// 重み付け
        const(Weight)[] weights() {return weights_;}
    }

private:

    /// メッシュ名
    string name_;

    /// オフセット行列
    const(mat4) offset_;

    /// 重み付け
    const(Weight)[] weights_;
}

/// メッシュ
class Mesh {

    /**
     *  Params:
     *      name = メッシュ名
     *      vertices = 頂点配列
     *      normals = 法線配列
     *      bones = ボーン配列
     *      faces = 面配列
     *      material = マテリアル
     */
    this(string name,
            const(vec3)[] vertices,
            const(vec3)[] normals,
            const(Bone)[] bones,
            const(uint[][uint]) faces,
            const(Material) material) @safe pure nothrow @nogc {
        name_ = name;
        vertices_ = vertices;
        normals_ = normals;
        bones_ = bones;
        faces_ = faces;
        material_ = material;
    }

    @property @safe const pure nothrow @nogc {

        /// メッシュ名
        string name() {return name_;}

        /// 頂点配列を返す
        const(vec3)[] vertices() {return vertices_;}

        /// 法線配列を返す
        const(vec3)[] normals() {return normals_;}

        /// ボーン
        const(Bone)[] bones() {return bones_;}

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

    /// ボーン配列
    const(Bone)[] bones_;

    /// 面配列
    const(uint[][uint]) faces_;

    /// マテリアル
    const(Material) material_;
}

