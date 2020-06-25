Shader "Custom/Outline"
{
    Properties
    {
        [HideInInspector]_MainTex("Base (RGB)", 2D) = "white" {}
        _Rate("Rate", Float) = 0.5
        _Strength("Strength", Float) = 0.7
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
			#pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            float4 _CameraDepthTexture_TexelSize;

            TEXTURE2D(_MaskTexture);
            SAMPLER(sampler_MaskTexture);

            float _Rate;
            float _Strength;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float2 uv[9] : TEXCOORD0;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;

                output.uv[0] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(-1, -1) * _Rate;
                output.uv[1] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(0, -1) * _Rate;
                output.uv[2] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(1, -1) * _Rate;
                output.uv[3] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(-1, 0) * _Rate;
                output.uv[4] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(0, 0) * _Rate;
                output.uv[5] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(1, 0) * _Rate;
                output.uv[6] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(-1, 1) * _Rate;
                output.uv[7] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(0, 1) * _Rate;
                output.uv[8] = input.uv + _CameraDepthTexture_TexelSize.xy * half2(1, 1) * _Rate;

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                const half Gx[9] = {
                    -1,  0,  1,
                    -2,  0,  2,
                    -1,  0,  1
                };

                const half Gy[9] = {
                    -1, -2, -1,
                    0,  0,  0,
                    1,  2,  1
                };
                
                float edgeY = 0;
                float edgeX = 0;    
                float luminance = 0;

                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[4]);
                float mask = 1;
                
                for (int i = 0; i < 9; i++) {
                    mask *= SAMPLE_DEPTH_TEXTURE(_MaskTexture, sampler_MaskTexture, input.uv[i]);
                }

                if (mask == 0) {
                    return color;
                }

                for (int i = 0; i < 9; i++) {
                    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv[i]);
                    luminance = LinearEyeDepth(depth, _ZBufferParams) * 0.1;
                    edgeX += luminance * Gx[i];
                    edgeY += luminance * Gy[i];
                }
                
                float edge = (1 - abs(edgeX) - abs(edgeY));
                edge = saturate(edge);

                return lerp(color * _Strength, color, edge);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}