Shader "Wave/GerstnerWave"
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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

            float4 GerstnerWave(float4 vertex)
            {
                float t = 2 * PI / _WaveLength;
                float value = t * ( vertex.x - _WaveSpeed * _Time.y );
                vertex.x+= _Amplitude * cos(value);
                vertex.y = _Amplitude * sin(value);
                return vertex;
            }

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex = GerstnerWave(v.vertex);
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
