module ddoom.camera;

import gl3n.math : cradians, clamp;

import gl3n.linalg;

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

    /// カメラ行列を返す
    @property mat4 matrix() {
        return mat4.identity
            .translate(
                -position_.x,
                -position_.y,
                -position_.z)
            .rotatex(rotation_.x)
            .rotatey(rotation_.y)
            .rotatez(rotation_.z);
    }

private:

    alias Vector!(real, 3) vec3r;

    /// カメラの位置
    vec3 position_ = vec3(0.0f, 0.0f, 0.0f);

    /// 画角
    vec3r rotation_ = vec3r(0.0, 0.0, 0.0);
}

