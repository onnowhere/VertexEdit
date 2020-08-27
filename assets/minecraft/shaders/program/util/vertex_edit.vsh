#version 120

attribute vec4 Position;

varying vec2 fragCoord;
varying vec2 texCoord;
varying vec2 inTexCoord;

uniform mat4 ProjMat;
uniform vec2 InSize;
uniform vec2 OutSize;
uniform vec2 ScreenSize;

uniform float _Unscale = 0.0; // Rescale image relative to pixel size instead of to buffer height (accepted values: 0, 1)
uniform float _CropPixel = 0.0; // Crop by pixels instead of ratios (accepted values: 0, 1)
uniform float _CropResize = 0.0; // Resize crop to fill original size (accepted values: 0, 1)
uniform float _CropRecenter = 0.0; // Recenter image after crop (accepted values: 0, 1)
uniform vec4 _Crop = vec4(0.0, 0.0, 0.0, 0.0); // Crop from xy corner to zw corner (set values to 0 to skip)
uniform float _Stretched = 0.0; // Stretch image horizontally to fill screen (accepted values: 0, 1)
uniform vec2 _StretchMin = vec2(0.0, 0.0); // Stretch image horizontally if screen ratio is larger than x/y ratio (set values to 0 to skip)
uniform vec2 _StretchMax = vec2(0.0, 0.0); // Maximum ratio to stop stretching after (set values to 0 to skip)
uniform float _ScalePixel = 0.0; // Scale by pixels instead of ratios (accepted values: 0, 1)
uniform vec2 _Scale = vec2(0.0, 0.0); // Scale image on x and y axes (set values to 0 to skip)
uniform float _OffsetPixel = 0.0; // Offset by pixels instead of ratios (accepted values: 0, 1)
uniform vec2 _Offset = vec2(0.0, 0.0); // Offset image on x and y axes
uniform vec2 _Align = vec2(0.0, 0.0); // Align to a corner or origin (accepted values: -1, 0, 1)
uniform vec2 _Flip = vec2(0.0, 0.0); // Flip horizontally or vertically (accepted values: 0, 1)
uniform float _RotPixel = 0.0; // Rotation origin by pixels instead of ratios (accepted values: 0, 1)
uniform float _RotGlobal = 0.0; // Rotation on global axis instead of local (accepted values: 0, 1)
uniform vec2 _RotOrigin = vec2(0.0, 0.0); // Rotation origin
uniform float _RotAngle = 0.0; // Rotation angle in degrees
uniform float _SkewPixel = 0.0; // Skew by pixels instead of ratios (accepted values: 0, 1)
uniform vec4 _Skew = vec4(0.0, 0.0, 0.0, 0.0); // Skew top corners and their opposite corner by values xy and zw (set values to 0 to skip)

void main() {
    vec2 minPos = vec2(-1.0);
    vec2 maxPos = vec2(1.0);

    float inSizeRatio = InSize.x / InSize.y;
    float outSizeRatio = OutSize.x / OutSize.y;
    float inoutSizeRatio = inSizeRatio / outSizeRatio;
    float inoutScaleRatio = InSize.y / OutSize.y;

    // Crop
    vec2 cropSize = _Crop.zw - _Crop.xy;
    vec2 cropMin = _Crop.xy;
    vec2 rescaleFactor = vec2(1.0);
    if (bool(_CropPixel)) {
        cropSize /= InSize;
        cropMin.x /= inoutSizeRatio;
        rescaleFactor = InSize;
    } else {
        cropMin *= InSize;
        cropMin.x /= inoutSizeRatio;
    }
    if (cropSize.x == 0 || cropSize.y == 0) {
        cropSize = vec2(1.0);
        cropMin = vec2(0.0);
    } else if (!bool(_CropResize)) {
        vec2 lowerOffset = _Crop.xy / rescaleFactor;
        vec2 upperOffset = _Crop.zw / rescaleFactor - vec2(1.0);
        minPos += lowerOffset * 2.0;
        maxPos += upperOffset * 2.0;
    }
    if (bool(_CropRecenter)) {
        vec2 centerAlign = vec2(0.0) - (minPos + maxPos) / 2.0;
        minPos += centerAlign;
        maxPos += centerAlign;
    }
    cropSize *= inoutScaleRatio;
    vec2 croppedPosition = Position.xy * cropSize + cropMin;
    croppedPosition.x *= inoutSizeRatio;
    
    // Unscale
    if (bool(_Unscale)) {
        minPos *= inoutScaleRatio;
        maxPos *= inoutScaleRatio;
    }

    // Stretch
    float stretchRatio = 1.0;
    bool doStretchMin = all(greaterThan(_StretchMin, vec2(0.0)));
    bool doStretchMax = all(greaterThan(_StretchMax, vec2(0.0)));
    if (doStretchMin || doStretchMax) {
        float stretchMinRatio = _StretchMin.x / _StretchMin.y;
        float stretchMaxRatio = _StretchMax.x / _StretchMax.y;
        if (doStretchMin && outSizeRatio < stretchMinRatio) {
            stretchRatio = outSizeRatio / stretchMinRatio;
        } else if (doStretchMax && outSizeRatio > stretchMaxRatio) {
            stretchRatio = outSizeRatio / stretchMaxRatio;
        }
        if (bool(_Stretched)) {
            stretchRatio = 1.0 / stretchRatio;
        }
        minPos.x *= stretchRatio;
        maxPos.x *= stretchRatio;
    }

    // Stretched
    if (!bool(_Stretched)) {
        minPos.x *= inoutSizeRatio;
        maxPos.x *= inoutSizeRatio;
    }
    
    // Flip
    if (bool(_Flip.x)) {
        croppedPosition.x = InSize.x - croppedPosition.x;
    }
    if (bool(_Flip.y)) {
        croppedPosition.y = InSize.y - croppedPosition.y;
    }

    // Scale
    vec2 scale = _Scale;
    if (bool(_ScalePixel)) {
        scale /= InSize;
    }
    if (scale.x != 0.0 && scale.y != 0.0) {
        minPos *= scale;
        maxPos *= scale;
    }

    // Align
    vec2 alignOffset = vec2(0.0, 0.0);
    if (_Align.x == -1.0) {
        alignOffset.x = _Align.x - minPos.x;
    } else if (_Align.x == 1.0) {
        alignOffset.x = _Align.x - maxPos.x;
    }
    if (_Align.y == -1.0) {
        alignOffset.y = _Align.y - minPos.y;
    } else if (_Align.y == 1.0) {
        alignOffset.y = _Align.y - maxPos.y;
    }
    minPos += alignOffset;
    maxPos += alignOffset;

    vec2 outPos = minPos;
    if (Position.x > 0.5) outPos.x = maxPos.x;
    if (Position.y > 0.5) outPos.y = maxPos.y;
    
    // Skew
    if (_Skew != vec4(0.0)) {
        vec4 skew = _Skew;
        if (bool(_SkewPixel)) {
            skew /= InSize.xyxy;
            skew.xz /= outSizeRatio;
        } else {
            skew *= abs(maxPos - minPos).xyxy;
        }
        if (skew.xy != vec2(0.0)) {
            if (Position.x < 0.5 && Position.y > 0.5) {
                outPos += skew.xy;
            } else if (Position.x > 0.5 && Position.y < 0.5) {
                outPos -= skew.xy;
            }
        }
        if (skew.zw != vec2(0.0)) {
            if (Position.x > 0.5 && Position.y > 0.5) {
                outPos += skew.zw;
            } else if (Position.x < 0.5 && Position.y < 0.5) {
                outPos -= skew.zw;
            }
        }
    }

    // Rotate
    if (_RotAngle != 0.0) {
        vec2 origin = _RotOrigin;
        if (bool(_RotPixel)) {
            origin *= 2.0;
            if (!bool(_RotGlobal)) {
                if (bool(_Stretched)) {
                    origin.x *= outSizeRatio;
                }
                origin.x *= stretchRatio;
                origin *= scale / inoutScaleRatio;
                origin += alignOffset * OutSize;
            }
            outPos *= OutSize;
        } else {
            if (!bool(_RotGlobal)) {
                if (!bool(_Stretched)) {
                    origin.x /= outSizeRatio;
                }
                origin.x *= stretchRatio;
                origin *= scale;
                origin += alignOffset;
            }
            outPos.x *= outSizeRatio;
            origin.x *= outSizeRatio;
        }
        float angle = radians(_RotAngle);
        mat2 rotation = mat2(
            cos(angle), -sin(angle),
            sin(angle), cos(angle)
        );
        outPos = origin + rotation * (outPos - origin);
        if (bool(_RotPixel)) {
            outPos /= OutSize;
        } else {
            outPos.x /= outSizeRatio;
        }
    }

    // Offset
    if (bool(_OffsetPixel)) {
        outPos += _Offset / (OutSize / 2.0);
    } else {
        outPos += _Offset;
    }

    gl_Position = vec4(outPos.xy, 0.2, 1.0);

    inTexCoord = croppedPosition.xy / InSize;
    texCoord = croppedPosition.xy / OutSize;
    fragCoord = croppedPosition.xy;
}
