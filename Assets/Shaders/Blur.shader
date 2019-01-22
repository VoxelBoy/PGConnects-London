Shader "_PGC/LWRP/Blur" {
    Properties {
        [PerRendererData] _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Size ("Size", Range(0, 20)) = 1
        _Sigma ("Sigma", Range(0, 3)) = 0.8
    }
 
    Category {
 
        Tags { "Queue"="Transparent" "RenderType" = "Transparent" "RenderPipeline" = "LightweightPipeline" "IgnoreProjector" = "True"}
 
        SubShader {
        
            Blend SrcAlpha OneMinusSrcAlpha
            
            Pass {
                Name "ForwardLit"
                Tags { "LightMode" = "LightweightForward" }
             
                HLSLPROGRAM
                
                // Required to compile gles 2.0 with standard srp library
                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 2.0
                
                #pragma vertex vert
                #pragma fragment frag
                #pragma fragmentoption ARB_precision_hint_fastest
                #include "UnityCG.cginc"
                
                struct appdata_t {
                    float4 vertex : POSITION;
                    float4 color    : COLOR;
                    float2 texcoord: TEXCOORD0;
                };
             
                struct v2f {
                    float4 vertex : POSITION;
                    half4 color    : COLOR0;
                    float4 uvgrab : TEXCOORD0;
                };
                
                v2f vert (appdata_t v) {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uvgrab = ComputeGrabScreenPos(o.vertex);
                    o.color = v.color;
                    return o;
                }
             
                half4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_TexelSize;
                float _Size;
                float _Sigma;
                
                #define PI 3.14159265
                #define KERNEL_SIZE 4
                
                float gauss(float x, float y, float sigma) {
                    return 1.0 / (2.0 * PI * sigma * sigma) * exp(-(x * x + y * y) / (2.0 * sigma * sigma));
                }
             
                half4 frag( v2f i ) : COLOR {
                
                    half4 o = 0;
                    float sum = 0;
                    float4 uvOffset;
                    float weight;
                    
                    for(int x = -KERNEL_SIZE / 2; x <= KERNEL_SIZE / 2; ++x)
                        for(int y = -KERNEL_SIZE / 2; y <= KERNEL_SIZE / 2; ++y)
                        {
                            uvOffset = i.uvgrab;
                            uvOffset.x += x * _MainTex_TexelSize.x * _Size;
                            uvOffset.y += y * _MainTex_TexelSize.y * _Size;
                            weight = gauss(x, y, _Sigma);
                            o += tex2D(_MainTex, uvOffset) * weight;
                            sum += weight;
                        }
                    o *= (1.0 / sum);
                    o.rgb *= _Color;
                    o.a = i.color.a;
                    return o;
                }
                
                ENDHLSL
            }
        }
    }
}