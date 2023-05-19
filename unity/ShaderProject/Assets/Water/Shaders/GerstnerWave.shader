Shader "Wave/GerstnerWave"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WaveLength("波浪长度",float)=1
        _WaveSpeed("波浪速度",float)=1
        _Steepness("波浪高度",Range(0,1))=0.1
        _Direction("波浪方向",Vector)=(0,0,0,0)
        _SpecularColor("高光颜色",Color)=(1,1,1,1)
        _Smoothness("光滑度",Range(0,1))=1
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
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewDir:TEXCOORD1;
                float3 normalWS:TEXCOORD2;
                float3 vertexWS:TEXCOORD3;
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Steepness;
            float _WaveLength;
            float _WaveSpeed;
            float4 _Direction;
            float4 _SpecularColor;
            float _Smoothness;
            CBUFFER_END

            float4 GerstnerWave(float4 vertex)
            {
                float t = 2 * PI / _WaveLength;
                float a = _Steepness/t;
                float2 direction = normalize(_Direction.xy);
                float waveVector = dot(vertex.xz,t*direction);
                float value =  ( waveVector )- _WaveSpeed * _Time.y ;
                vertex.x+= a * cos(value)*direction.x;
                vertex.y = a * sin(value);
                vertex.z+=a*cos(value)*direction.y;
                return vertex;
            }

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex = GerstnerWave(v.vertex);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.vertexWS = TransformObjectToWorldNormal(v.vertex.xyz);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv);
                float3 normalWS = normalize(i.normalWS);
                float3 viewDireWS = normalize(_WorldSpaceCameraPos-i.vertexWS);

                //Lighting
                Light light = GetMainLight();
                half3 lambert = LightingLambert(light.color,light.direction,normalWS);
                half3 blinnPhong = LightingSpecular(light.color,light.direction,normalWS,viewDireWS,_SpecularColor,_Smoothness);
                col.xyz*=lambert;

                return col;
            }
            ENDHLSL
        }
    }
}
