Shader "_PGC/LWRP/LitVertexColor"
{
    Properties
    {
        _AmbientContribution ("Ambient Contribution", Range(0,1)) = 1
        _DiffuseContribution ("Diffuse Contribution", Range(0,1)) = 1
        _VertexColorContribution ("Vertex Color Contribution", Range(0,1)) = 1
    }
    SubShader
    {
        Pass
        {
            Tags {"RenderPipeline" = "LightweightPipeline" "LightMode" = "LightweightForward" }

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Lightweight Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

            #pragma vertex LitPassVertexSimple
            #pragma fragment LitPassFragmentSimple

            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                half _AmbientContribution;
                half _DiffuseContribution;
                half _VertexColorContribution;
            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS    : POSITION;
                float3 normalOS      : NORMAL;
                float3 color         : COLOR;
            };
            
            struct Varyings
            {
                float3 color         : COLOR;
                half3 vertexSH       : TEXCOORD1;
                half3 normalWS       : TEXCOORD2;
                float4 shadowCoord   : TEXCOORD3;
                float4 positionCS    : SV_POSITION;
            };
            
            Varyings LitPassVertexSimple(Attributes input)
            {
                Varyings output = (Varyings)0;
            
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
            
                output.positionCS = vertexInput.positionCS;
                output.normalWS = normalInput.normalWS;
                output.color = input.color;
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                output.shadowCoord = GetShadowCoord(vertexInput);
            
                return output;
            }
            
            half4 LitPassFragmentSimple(Varyings input) : SV_Target
            {
                half3 normalWS = NormalizeNormalPerPixel(input.normalWS);
                half3 ambient = SampleSHPixel(input.vertexSH, normalWS) * _AmbientContribution;
            
                Light mainLight = GetMainLight(input.shadowCoord);
                half ndotl = saturate(dot(normalWS, mainLight.direction));
                half3 attenuatedLightColor = mainLight.color * ndotl * mainLight.shadowAttenuation * _DiffuseContribution;
                half3 diffuseColor = ambient + attenuatedLightColor;
                half3 vertexColor = lerp(half3(1,1,1), input.color, _VertexColorContribution);
                
                half3 finalColor = diffuseColor * vertexColor;
                return half4(finalColor, 1);
            };

            ENDHLSL
        }
        
        // Pass to render object as a shadow caster
        // NOTE: Pulled in ShadowCasterPass.hlsl code here to get rid of usage of MainTex 
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
    
            ZWrite On ZTest LEqual Cull Off
    
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Shadows.hlsl"
            
            float3 _LightDirection;
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };
            
            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
            };
            
            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldDir(input.normalOS);
            
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
            
            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #endif
            
                return positionCS;
            }
            
            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }
            
            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
