module ddoom.camera;

import std.stdio;

import gl3n.math : cradians, clamp;

import gl3n.linalg;
import gl3n.math;

@safe:

/**
 *  視点の変換を行うカメラ
 */
struct Camera {

    /// X軸の回転
    ref Camera rotateX(real x) {
        rotation_.x += x;
        return this;
    }

    /// Y軸の回転
    ref Camera rotateY(real y) {
        rotation_.y += y;
        return this;
    }

    /// Z軸の回転
    ref Camera rotateZ(real z) {
        rotation_.z += z;
        return this;
    }

    /// 現在位置から移動する
    ref Camera moveX(float x) {
        position_.x += x;
        return this;
    }

    /// ditto
    ref Camera moveY(float y) {
        position_.y += y;
        return this;
    }

    /// ditto
    ref Camera moveZ(float z) {
        position_.z += z;
        return this;
    }

    /// ditto
    ref Camera move(float x, float y, float z) {
        immutable d = vec3(x, y, z);
        return move(d);
    }

    /// ditto
    ref Camera move(vec3 distance) {
        return move(distance);
    }

    /// ditto
    ref Camera move(ref const vec3 distance) {
        position_ += distance;
        return this;
    }

    /// 平行投影に設定する
    ref Camera orthogonal(float l, float r, float b, float t, float n, float f) {
        projection_ = mat4.orthographic(l, r, b, t, n, f);
        return this;
    }

    /// 透視投影に設定する
    ref Camera perspective(float w, float h, float fov, float n, float f) {
        projection_ = mat4.perspective(w, h, fov, n, f);
        return this;
    }

    /// プロジェクション行列を返す
    @property mat4 projection() const nothrow pure @nogc {
        return projection_;
    }

    /// ビュー行列を返す
    @property mat4 view() const nothrow pure @nogc {
        return mat4.translation(
                -position_.x, -position_.y, -position_.z)
            .rotatex(rotation_.x)
            .rotatey(rotation_.y)
            .rotatez(rotation_.z);
    }

    /// 視点変換行列を返す
    mat4 matrix(ref const mat4 model) const {
        return projection_ * view * model;
    }

private:

    alias Vector!(real, 3) vec3r;

    /// カメラの位置
    vec3 position_ = vec3(0.0f, 0.0f, 0.0f);

    /// 画角
    vec3r rotation_ = vec3r(0.0, 0.0, 0.0);

    /// 射影変換行列
    mat4 projection_ = mat4.identity;
}

