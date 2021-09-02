using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.Mathf;

public static class SSSSKernel
{
    public static Vector3 Gaussian(float variance,float r,Vector3 falloff) {
        Vector3 g = Vector3.zero;
        for (int i = 0; i < 3; i++)
        {
            float rr = r / (0.001f + falloff[i]);
            g[i] = Exp(-(rr * rr) / (2 * variance)) / (2 * 3.14f * variance);
        }
        return g;
    }
    public static Vector3 Profile(float r,Vector3 falloff)
    {
        var weights = new[] { 0.1f,0.118f,0.113f,0.358f,0.078f};
        var variances = new[] {0.0484f,0.187f,0.567f,1.99f,7.41f };
        const int count = 5;
        var g = Vector3.zero;
        for (int i = 0; i < count; i++)
        {
            g += weights[i] * Gaussian(variances[i], r,falloff);
        }
        return g;
    }

    public static void CalculateKernel(List<Vector4> kernel,int samplers,Color strengthColor,Color falloffColor)
    {
        var strength = new Vector3(strengthColor.r, strengthColor.g, strengthColor.b);
        var falloff = new Vector3(falloffColor.r, falloffColor.g, falloffColor.b);
        CalculateKernel(kernel, samplers, strength, falloff);
    }

    public static void CalculateKernel(List<Vector4> kernel,int samples,Vector3 strength,Vector3 falloff)
    {

        float RANGE = samples > 20 ? 3f:2f;
        const float EXPONENT = 2f;
        kernel.Clear();

        // calc offset
        float step = 2f * RANGE / (samples - 1);
        float rangePow = Pow(RANGE, EXPONENT);
        for (int i = 0; i < samples; i++)
        {
            float o = -RANGE + i * step;
            float sign = o < 0 ? -1 : 1;

            var w = RANGE * sign * Abs(Pow(o, EXPONENT)) / rangePow;
            kernel.Add(new Vector4(0,0,0,w));
        }

        //calc weights
        for (int i = 0; i < samples; i++)
        {
            float w0 = i > 0 ? Abs(kernel[i].w - kernel[i - 1].w) : 0f;
            float w1 = i < samples - 1 ? Abs(kernel[i].w - kernel[i + 1].w) : 0f;
            float area = (w0 + w1) / 2f;
            var t = area * Profile(kernel[i].w,falloff);
            var item = kernel[i];
            kernel[i] = new Vector4(t.x, t.y, t.z, item.w);
        }
        // We want the offset 0.0 to come first:
        Vector4 v = kernel[samples / 2];
        for (int i = samples/2; i > 0; i--)
        {
            kernel[i] = kernel[i - 1];
        }
        kernel[0] = v;

        var sum = Vector4.zero;
        for (int i = 0; i < samples; i++)
        {
            sum += kernel[i];
        }
        // normalized
        for (int i = 0; i < samples; i++)
        {
            var item = kernel[i];
            item.x /= sum.x;
            item.y /= sum.y;
            item.z /= sum.z;
            kernel[i] = item;
        }
        // Tweak them using the desired strength. The first one is:
        //     lerp(1.0, kernel[0].rgb, strength)
        var item0 = kernel[0];
        item0.x = Lerp(1f, item0.x, strength.x);
        item0.y = Lerp(1f, item0.y, strength.y);
        item0.z = Lerp(1f, item0.z, strength.z);
        kernel[0] = item0;
        // The others:
        //     lerp(0.0, kernel[0].rgb, strength)
        for (int i = 1; i < samples; i++)
        {
            var item = kernel[i];
            item.x *= strength.x;
            item.y *= strength.y;
            item.z *= strength.z;
            kernel[i] = item;
        }
    }
}
