Shader "_PGC/Legacy/LitVertexColor"
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
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            
            half _AmbientContribution;
            half _DiffuseContribution;
            half _VertexColorContribution;
            
            half4 _LightColor0;
            
            struct Attributes
            {
                float4 positionOS    : POSITION;
                float3 normalOS      : NORMAL;
                float4 color         : COLOR;
            };
            
            struct Varyings
            {
                half4 color          : COLOR;
                half3 vertexSH       : TEXCOORD1;
                half3 normalWS       : TEXCOORD2;
                float4 _ShadowCoord  : TEXCOORD3;
                float4 pos           : SV_POSITION;
            };
            
            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
            
                output.pos = UnityObjectToClipPos(input.positionOS);
                output.normalWS = UnityObjectToWorldNormal(input.normalOS);
                output.color = input.color;
                TRANSFER_SHADOW(output);
                output.vertexSH = ShadeSH9 (float4(output.normalWS,1.0)) * _AmbientContribution;

                return output;
            }
            
            half4 frag (Varyings input) : SV_TARGET
            {
                half3 normalWS = normalize(input.normalWS);
                
                half ndotl = saturate(dot(normalWS, _WorldSpaceLightPos0.xyz));
                half3 attenuatedLightColor = _LightColor0.rgb * ndotl * SHADOW_ATTENUATION(input) * _DiffuseContribution;
                half3 diffuseColor = input.vertexSH + attenuatedLightColor;
                half3 vertexColor = lerp(half3(1,1,1), input.color, _VertexColorContribution);
                
                half3 finalColor = diffuseColor * vertexColor;
                return half4(finalColor, 1);
            }
            ENDCG
        }
        
        // Pass to render object as a shadow caster
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
    
            ZWrite On ZTest LEqual Cull Off
    
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"
    
            struct v2f {
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_OUTPUT_STEREO
            };
    
            v2f vert( appdata_base v )
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }
    
            float4 frag( v2f i ) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
