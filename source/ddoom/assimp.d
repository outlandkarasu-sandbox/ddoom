/**
 *  ASSIMP関連のユーティリティモジュール
 */ 
module ddoom.assimp;

import std.algorithm : map;
import std.array : array, Appender;
import std.stdio : writefln;
import std.string : fromStringz, toStringz;
import std.format : format;

import derelict.assimp3.assimp;
import gl3n.linalg;

import ddoom.asset;

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
        throw new AssetException(errorMessage, file, line);
    }
    return value;
}

/// シーンのアセット
class SceneAsset {

    /// 指定パスのシーンファイルを開く
    this(string path) {
        scene_ = enforceAsset(aiImportFile(
                    toStringz(path),
                    aiProcess_CalcTangentSpace
                    | aiProcess_Triangulate
                    | aiProcess_JoinIdenticalVertices
                    | aiProcess_SortByPType));
    }

    /// シーンの破棄
    ~this() nothrow {
        release();
    }

    /// シーンを生成する
    Scene createScene() const
    in {
        assert(scene_ !is null);
    } body {
        if(scene_.mRootNode is null) {
            return new Scene(null, null);
        }

        // マテリアル情報
        auto materials
            = scene_.mMaterials[0 .. scene_.mNumMaterials]
            .map!(m => createMaterial(m))
            .array;

        // メッシュ配列
        auto meshes
            = scene_.mMeshes[0 .. scene_.mNumMeshes]
            .map!(m => createMesh(m, materials))
            .array;

        // ルートノード
        auto root = createNode(scene_.mRootNode, meshes);

        // アニメーション
        auto animations
            = scene_.mAnimations[0 .. scene_.mNumAnimations]
            .map!(a => createAnimation(a))
            .array;

        return new Scene(root, animations);
    }

    /// シーンの解放
    void release() nothrow {
        aiReleaseImport(scene_);
        scene_ = null;
    }

private:

    /// 文字列変換
    static string fromAiString(const(aiString) s) @safe pure {
        return s.data[0 .. s.length].idup;
    }

    /// 色情報の変換
    static Material.Color fromAiColor(ref const(aiColor4D) c) @safe nothrow pure @nogc {
        return Material.Color(c.r, c.g, c.b, c.a);
    }

    /// 行列変換
    static mat4 fromAiMatrix4x4(ref const aiMatrix4x4 m) @safe pure nothrow @nogc {
        return mat4(
                m.a1, m.a2, m.a3, m.a4,
                m.b1, m.b2, m.b3, m.b4,
                m.c1, m.c2, m.c3, m.c4,
                m.d1, m.d2, m.d3, m.d4);
    }

    /// ベクトルの変換
    static vec3 fromAiVector(ref const aiVector3D v) @safe pure nothrow @nogc {
        return vec3(v.x, v.y, v.z);
    }

    /// 四元数の変換
    static quat fromAiQuaternion(ref const aiQuaternion q) @safe pure nothrow @nogc {
        return quat(q.w, q.x, q.y, q.z);
    }

    /// アニメーションの生成
    Animation createAnimation(const(aiAnimation)* animation) const {
        // ノード名
        auto name = fromAiString(animation.mName);

        // 長さ
        auto duration = animation.mDuration;

        // 秒間フレーム数
        auto ticksPerSecond = animation.mTicksPerSecond;

        // 各チャンネルのアニメーション
        auto channels
            = animation.mChannels[0 .. animation.mNumChannels]
                .map!(c => createNodeAnimation(c))
                .array;

        return new Animation(name, duration, ticksPerSecond, channels);
    }

    /// ノードのアニメーションの生成
    NodeAnimation createNodeAnimation(const(aiNodeAnim)* channel) const {
        // ノード名
        auto nodeName = fromAiString(channel.mNodeName);

        // ベクトルキーの変換
        static NodeAnimation.VectorKey fromAiVectorKey(
                ref const aiVectorKey key) {
            return NodeAnimation.VectorKey(
                    key.mTime, fromAiVector(key.mValue));
        }

        // 四元数キーの変換
        static NodeAnimation.QuaternionKey fromAiQuatKey(
                ref const aiQuatKey key) {
            return NodeAnimation.QuaternionKey(
                    key.mTime, fromAiQuaternion(key.mValue));
        }

        // 位置のキーフレーム
        auto positionKeys
            = channel.mPositionKeys[0 .. channel.mNumPositionKeys]
                .map!(p => fromAiVectorKey(p))
                .array;

        // 回転のキーフレーム
        auto rotationKeys
            = channel.mRotationKeys[0 .. channel.mNumRotationKeys]
                .map!(r => fromAiQuatKey(r))
                .array;

        // スケールのキーフレーム
        auto scalingKeys
            = channel.mScalingKeys[0 .. channel.mNumScalingKeys]
                .map!(s => fromAiVectorKey(s))
                .array;

        return new NodeAnimation(
                nodeName, positionKeys, rotationKeys, scalingKeys);
    }

    /// ノードの生成
    Node createNode(const(aiNode)* node, const(Mesh)[] meshes) const {
        // ノード名
        auto name = fromAiString(node.mName);

        // 子ノード配列
        auto children
                = node.mChildren[0 .. node.mNumChildren]
                    .map!(c => createNode(c, meshes))
                    .array;

        // 変換行列
        auto trans = fromAiMatrix4x4(node.mTransformation);

        return new Node(name, meshes, children, trans);
    }

    /// マテリアルの生成
    Material createMaterial(const(aiMaterial)* material) const {
        // マテリアル名
        aiString aiName;
        aiGetMaterialString(material, AI_MATKEY_NAME, 0, 0, &aiName);
        auto name = fromAiString(aiName);

        aiColor4D color;

        // 表面色
        aiGetMaterialColor(material, AI_MATKEY_COLOR_DIFFUSE, 0, 0, &color);
        auto diffuse = fromAiColor(color);

        aiGetMaterialColor(material, AI_MATKEY_COLOR_SPECULAR, 0, 0, &color);

        // ハイライト色
        auto speculer = fromAiColor(color);

        aiGetMaterialColor(material, AI_MATKEY_COLOR_AMBIENT, 0, 0, &color);

        // 環境色
        auto ambient = fromAiColor(color);

        return new Material(name, diffuse, speculer, ambient);
    }

    /// ボーンの生成
    Bone createBone(const(aiBone)* bone) const {
        // ボーン名
        auto name = fromAiString(bone.mName);

        // オフセット
        auto offset = fromAiMatrix4x4(bone.mOffsetMatrix);

        // 重み付け
        auto weights = bone.mWeights[0 .. bone.mNumWeights]
            .map!(b => Bone.Weight(b.mVertexId, b.mWeight))
            .array;

        return new Bone(name, offset, weights);
    }

    /// メッシュの生成
    Mesh createMesh(const(aiMesh)* mesh, const(Material)[] materials) const {
        // メッシュ名
        auto name = fromAiString(mesh.mName);

        // 頂点配列
        auto vertices
            = mesh.mVertices[0 .. mesh.mNumVertices]
                .map!(v => fromAiVector(v))
                .array;

        // 法線配列
        const(vec3)[] normals;
        if(mesh.mNormals !is null) {
            normals = mesh.mNormals[0 .. mesh.mNumVertices]
                .map!(n => fromAiVector(n))
                .array;
        }

        // ボーン配列
        const(Bone)[] bones;
        if(mesh.mBones !is null) {
            bones = mesh.mBones[0 .. mesh.mNumBones]
                .map!(b => createBone(b))
                .array;
        }

        // 面配列。頂点数別にまとめる
        Appender!(uint[])[uint] faces;
        foreach(f; mesh.mFaces[0 .. mesh.mNumFaces]) {
            immutable n = f.mNumIndices;
            auto app = n in faces;
            if(app is null) {
                app = &(faces[n] = Appender!(uint[])());
            }
            app.put(f.mIndices[0 .. n]);
        }

        uint[][uint] facesArray;
        foreach(e; faces.byKeyValue) {
            facesArray[e.key] = e.value.data;
        }
        facesArray.rehash;

        // マテリアルの取得
        immutable mi = mesh.mMaterialIndex;
        auto material = (mi < materials.length) ? materials[mi] : null;
        return new Mesh(
                name, vertices, normals, bones, facesArray, material);
    }

    /// シーンへのポインタ
    const(aiScene)* scene_;
}

