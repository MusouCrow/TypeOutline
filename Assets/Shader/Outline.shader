Shader "Custom/Outline"
{
    Properties
    {
        [HideInInspector]_MainTex("Base (RGB)", 2D) = "white" {}
        _Color("Color", Color) = (0, 0, 0, 1)
        _Thickness("Thickness", float) = 1
        _Sensitivity("Sensitivity", float) = 1
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma vertex vert
			#pragma fragment frag

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            float4 _CameraDepthTexture_TexelSize;

            TEXTURE2D(_TestTexture);
            SAMPLER(sampler_TestTexture);

            float4 _Color;
            float _Thickness;
            float _Sensitivity;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv[4] : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float SampleDepth(float2 uv)
            {
                return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
            }

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;

                float halfScaleFloor = floor(_Thickness * 0.5);
                float halfScaleCeil = ceil(_Thickness * 0.5);
                float2 texel = 1 / float2(_CameraDepthTexture_TexelSize.z, _CameraDepthTexture_TexelSize.w);

                output.uv[0] = input.uv - float2(texel.x, texel.y) * halfScaleFloor;
                output.uv[1] = input.uv + float2(texel.x, texel.y) * halfScaleCeil;
                output.uv[2] = input.uv + float2(texel.x * halfScaleCeil, -texel.y * halfScaleFloor);
                output.uv[3] = input.uv + float2(-texel.x * halfScaleFloor, texel.y * halfScaleCeil);

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float depths[4];
                float alphas[4];

                for (int i = 0; i < 4 ; i++)
                {
                    depths[i] = SampleDepth(input.uv[i]);
                    alphas[i] = SAMPLE_DEPTH_TEXTURE(_TestTexture, sampler_TestTexture, input.uv[i]);
                }

                float finiteDifference0 = (depths[1] - depths[0]) * (alphas[1] - alphas[0]);
                float finiteDifference1 = (depths[3] - depths[2]) * (alphas[3] - alphas[2]);
                float edge = sqrt(pow(finiteDifference0, 2) + pow(finiteDifference1, 2)) * 100;
                float threshold = (1 / _Sensitivity) * depths[0];
                edge = edge > threshold ? 1 : 0;

                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[0]);

                return ((1 - edge) * color) + (edge * lerp(color, _Color,  _Color.a));
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}