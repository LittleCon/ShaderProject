Shader "Wave/SinWave"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Amplitude("波浪高度",float)=1
        _WaveLength("波浪长度",float)=1
        _WaveSpeed("波浪速度",float)=1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

    

        Pass
        {
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Amplitude;
            float _WaveLength;
            float _WaveSpeed;
            CBUFFER_END

            //原理依据正弦波函数 y=Asin(wx+t)
            float SinWave(float x)
            {
                 float t = 2 * PI / _WaveLength;
                 float value = t*(x-_WaveSpeed*_Time.y);
                 float waveOffset = _Amplitude * sin(value);
                 return waveOffset;
            }

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.y += SinWave(v.vertex.x);
                v.vertex.y+=SinWave(v.vertex.z);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv);
                return col;
            }
            ENDHLSL
        }
    }
}
