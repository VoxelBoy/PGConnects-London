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
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            fixed _AmbientContribution;
            fixed _DiffuseContribution;
            fixed _VertexColorContribution;
            
            struct VertexOutput
            {
                UNITY_POSITION(pos);
                half3 normalWorld : TEXCOORD1;
                fixed3 ambient : TEXCOORD2;
                half4 color : COLOR;
                LIGHTING_COORDS(3,4)
            };
            
            VertexOutput vert (appdata_full v)
            {
                VertexOutput o;
                UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
            
                float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normalWorld = UnityObjectToWorldNormal(v.normal);
            
                o.ambient = ShadeSH9 (float4(o.normalWorld,1.0)) * _AmbientContribution;
                o.color = v.color;
                
                //We need this for shadow receiving
                TRANSFER_SHADOW(o);

                return o;
            }
            
            half4 frag (VertexOutput i) : SV_TARGET
            {
                half ndotl = saturate(dot(i.normalWorld, _WorldSpaceLightPos0.xyz));
                half shadow = SHADOW_ATTENUATION(i);
                half3 attenuatedLightColor = (_LightColor0.rgb * ndotl) * shadow * _DiffuseContribution;
                half3 vertexColor = lerp(half3(1,1,1), i.color, _VertexColorContribution);
                half3 finalColor = vertexColor * (attenuatedLightColor + i.ambient);
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
            #pragma multi_compile_shadowcaster
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
