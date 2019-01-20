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
            // Lightweight Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

            #pragma vertex LitPassVertexSimple
            #pragma fragment LitPassFragmentSimple

            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
            
            half _AmbientContribution;
            half _DiffuseContribution;
            half _VertexColorContribution;
            
            struct Attributes
            {
                float4 positionOS    : POSITION;
                float3 normalOS      : NORMAL;
                float3 color         : COLOR;
            };
            
            struct Varyings
            {
                float3 color                    : COLOR;
                half3 vertexSH                  : TEXCOORD1;
                half3 normal                   : TEXCOORD2;
                float4 shadowCoord              : TEXCOORD3;
                float4 positionCS               : SV_POSITION;
            };
            
            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////
            
            // Used in Standard (Simple Lighting) shader
            Varyings LitPassVertexSimple(Attributes input)
            {
                Varyings output = (Varyings)0;
            
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
            
                output.color = input.color;
                output.positionCS = vertexInput.positionCS;
                output.normal = normalInput.normalWS;
                OUTPUT_SH(output.normal.xyz, output.vertexSH);
                output.shadowCoord = GetShadowCoord(vertexInput);
            
                return output;
            }
            
            // Used for StandardSimpleLighting shader
            half4 LitPassFragmentSimple(Varyings input) : SV_Target
            {
                half3 normalWS = NormalizeNormalPerPixel(input.normal);
                half3 bakedGI = SampleSHPixel(input.vertexSH, normalWS) * _AmbientContribution;
            
                Light mainLight = GetMainLight(input.shadowCoord);
                half3 attenuatedLightColor = mainLight.color * mainLight.shadowAttenuation * _DiffuseContribution;
                half3 diffuseColor = bakedGI + LightingLambert(attenuatedLightColor, mainLight.direction, normalWS);
            
                half3 vertexColor = lerp(half3(1,1,1), input.color, _VertexColorContribution);
                
                half3 finalColor = diffuseColor * vertexColor;
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

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.lightweight/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
}
