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
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal:TEXCOORD1;
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Amplitude;
            float _WaveLength;
            float _WaveSpeed;
            CBUFFER_END

            //原理依据正弦波函数 y=Asin(wx+t)
            float SinWave(float x,float t)
            {
                 float value = t*(x-_WaveSpeed*_Time.y);
                 float waveOffset = _Amplitude * sin(value);
                 return waveOffset;
            }

            float3 GetTangent(float x,float t)
            {
                float value =t*(x-_WaveSpeed*_Time.y);
                float tangentY = _Amplitude*t*cos(value);
                return float3 (1,tangentY,0);
            }

            v2f vert (appdata v)
            {
                v2f o;
                float t = 2 * PI / _WaveLength;

                v.vertex.y += SinWave(v.vertex.x,t);
                v.vertex.y+=SinWave(v.vertex.z,t);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                float3 tangent = normalize(GetTangent(v.vertex.x,t));
                float3 bitangent = (0,0,1);
                float3 normal = normalize(cross(bitangent,tangent));
                v.normal = normal;
                o.normal=normal;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                return float4(i.normal,1);
            }
            ENDHLSL
        }
    }
}
