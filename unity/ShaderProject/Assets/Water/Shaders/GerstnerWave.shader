Shader "Wave/GerstnerWave"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _WaveA("波浪A参数([x,y]-波浪方向,z-波浪高度，w-波浪长度)",Vector)=(1,1,1,1)
        _WaveB("波浪B参数([x,y]-波浪方向,z-波浪高度，w-波浪长度)",Vector)=(1,1,1,1)
        _WaveSpeed("波浪速度",float)=1
        _SpecularColor("高光颜色",Color)=(1,1,1,1)
        _Smoothness("光滑度",Range(0,1))=1

        _depth_control("depth_control", Range(-0.2, 0.2)) = 0.01

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

                float4 screenPos:TEXCOORD4;
                
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            SAMPLER(sample_CameraDepthTexture);
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _WaveA;
            float4 _WaveB;
            float _WaveSpeed;
            float4 _SpecularColor;
            float4 _Color;
            float _Smoothness;
            float _depth_control;
            CBUFFER_END

            float3 GerstnerWave(float4 wave,float3 vertex,inout float3 tangent,inout float3 binormal)
            {
                float stepness=wave.z;
                float wavelength=wave.w;
                float k = 2 * PI / wavelength;
                float2 dir = normalize(wave.xy);
                float f = k * (dot (dir,vertex.xz)- _WaveSpeed * _Time.y);
                float a = stepness/k;

                
                tangent += float3(-dir.x*dir.x*stepness*sin(f),dir.x*stepness*cos(f),-dir.x*dir.y*stepness*sin(f));
                binormal += float3 (-dir.x*dir.y*stepness*sin(f),dir.x*stepness*cos(f),-dir.y*dir.y*stepness*sin(f));

                return float3( dir.x * a * cos(f), a * sin(f),dir.y * (a * cos(f)));
            
            }

            half4 cosine_gradient(float x,  half4 phase, half4 amp, half4 freq, half4 offset)//生成渐变颜色
            {
	            const float TAU = 2. * 3.14159265;
                phase *= TAU;
                x *= TAU;
                return half4(offset.r + amp.r * 0.5 * cos(x * freq.r + phase.r) + 0.5,
        	        offset.g + amp.g * 0.5 * cos(x * freq.g + phase.g) + 0.5,
                    offset.b + amp.b * 0.5 * cos(x * freq.b + phase.b) + 0.5,
                    offset.a + amp.a * 0.5 * cos(x * freq.a + phase.a) + 0.5);
            }

            // Z buffer to linear 0..1 depth
            // float Linear01Depth(float depth, float4 zBufferParam)
            // {
            //     return 1.0 / (zBufferParam.x * depth + zBufferParam.y);
            // }
            // Z buffer to linear depth
            // float LinearEyeDepth(float depth, float4 zBufferParam)
            // {
            //     return 1.0 / (zBufferParam.z * depth + zBufferParam.w);
            // } 



            v2f vert (appdata v)
            {
                v2f o;
                float3 tangent = 0;
                float3 binormal = 0;
                float3 vertex = v.vertex.xyz;
                vertex += GerstnerWave(_WaveA,v.vertex.xyz,tangent,binormal);
                vertex += GerstnerWave(_WaveB,v.vertex.xyz,tangent,binormal);
                tangent.x=1-saturate(tangent.x);
                binormal.z=1-saturate(binormal.z);
                v.vertex.xyz=vertex;
                v.normal = normalize(cross(binormal,tangent));
                
                //v.normal.y = 1 - v.normal.y; 
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.vertexWS = TransformObjectToWorldNormal(v.vertex.xyz);

                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }


            float4 frag (v2f i) : SV_Target
            {
                //水体颜色
                //采样深度图
                float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture,sampler_CameraDepthTexture,i.screenPos.xy/i.screenPos.w).r;
                float deptheye = LinearEyeDepth(depth, _ZBufferParams);

                //获取场景深度与水面的距离差值，获取[0,1]之间的值(大于1取1，小于0取0，其他取中间)
                float depth_D_value = saturate((deptheye - i.screenPos.z) * _depth_control);

                //定义渐变色
                //周期
                const half4 phases = half4(0.28,0.50,0.07,0);
                //振幅 
                const half4 amplitudes = half4 (4.02,0.32,0.65,0);
                //频率
                const half4 frequencies = half4(0,0.48,0.08,0);
                //相位
                const half offsets = half4(0,0.16,0,0);

                half4 cos_grad = cosine_gradient(saturate(1.5-depth_D_value),phases,amplitudes,frequencies,offsets);

                //限制值在[0,1]
                cos_grad = clamp(cos_grad,0,1);

                // sample the texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv)*_Color;
                float3 normalWS = normalize(i.normalWS);
                float3 viewDireWS = normalize(_WorldSpaceCameraPos-i.vertexWS);

                //Lighting
                Light light = GetMainLight();
                half3 lambert = LightingLambert(light.color,light.direction,normalWS);
                half3 blinnPhong = LightingSpecular(light.color,light.direction,normalWS,viewDireWS,_SpecularColor,_Smoothness);
                col.xyz*=lambert;

                return cos_grad;
                return float4(normalWS,1);
            }
            ENDHLSL
        }
    }
}
