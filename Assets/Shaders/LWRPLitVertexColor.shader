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
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "LightweightPipeline"}

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "LightweightForward" }

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Lightweight Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitPassVertexSimple
            #pragma fragment LitPassFragmentSimple
            #define BUMP_SCALE_NOT_SUPPORTED 1

            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS    : POSITION;
                float3 normalOS      : NORMAL;
                float3 color         : COLOR;
            };
            
            struct Varyings
            {
                float3 color                    : COLOR;
                float2 uv                       : TEXCOORD0;
                half3 vertexSH                  : TEXCOORD1;
                float3 posWS                    : TEXCOORD2;
            
                half3  normal                   : TEXCOORD3;
                half3 viewDir                   : TEXCOORD4;
            
            #ifdef _MAIN_LIGHT_SHADOWS
                float4 shadowCoord              : TEXCOORD5;
            #endif
            
                float4 positionCS               : SV_POSITION;
            };
            
            struct InputDataCustom
            {
                float3  positionWS;
                half3   normalWS;
                half3   viewDirectionWS;
                float4  shadowCoord;
                half3   bakedGI;
            };
            
            void InitializeInputData(Varyings input, out InputDataCustom inputData)
            {
                inputData.positionWS = input.posWS;
            
                half3 viewDirWS = input.viewDir;
                inputData.normalWS = input.normal;
            
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
            
                inputData.viewDirectionWS = viewDirWS;
            #if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
                inputData.shadowCoord = input.shadowCoord;
            #else
                inputData.shadowCoord = float4(0, 0, 0, 0);
            #endif
                inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
            }
            
            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////
            
            // Used in Standard (Simple Lighting) shader
            Varyings LitPassVertexSimple(Attributes input)
            {
                Varyings output = (Varyings)0;
            
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
                half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
            
                viewDirWS = SafeNormalize(viewDirWS);
            
                output.color = input.color;
            
                output.posWS = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;
            
                output.normal = normalInput.normalWS;
                output.viewDir = viewDirWS;
            
                OUTPUT_SH(output.normal.xyz, output.vertexSH);
            
            #if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
                output.shadowCoord = GetShadowCoord(vertexInput);
            #endif
            
                return output;
            }
            
            // Used for StandardSimpleLighting shader
            half4 LitPassFragmentSimple(Varyings input) : SV_Target
            {
                InputDataCustom inputData;
                InitializeInputData(input, inputData);
            
                //half4 color = LightweightFragmentBlinnPhong(inputData, diffuse, specularGloss, shininess, emission, alpha);
                
                Light mainLight = GetMainLight(inputData.shadowCoord);
                MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));
            
                half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
                half3 diffuseColor = inputData.bakedGI + LightingLambert(attenuatedLightColor, mainLight.direction, inputData.normalWS);
            
                half3 finalColor = diffuseColor * input.color;
            
                return half4(finalColor, 1);
            };

            ENDHLSL
        }
        
        // Pass to render object as a shadow caster
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

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.lightweight/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On ColorMask 0 Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.lightweight/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
}
