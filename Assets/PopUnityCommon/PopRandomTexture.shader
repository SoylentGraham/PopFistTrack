Shader "PopUnityCommon/PopRandomTexture" {
	Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		GenerateRandomAlpha ("GenerateRandomAlpha", Int) = 0
		MagicNumberA ("MagicNumberA", Vector) = (12.9898,78.233,43758.5453)
		MagicNumberB ("MagicNumberB", Vector) = (1.0,2.0,3.0,4.0)
		MagicNumberC ("MagicNumberB", Vector) = (3.0,1.0,4.0,2.0)
	}
	SubShader {
	
	pass
	{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
	
			struct VertexInput {
				float4 Position : POSITION;
				float2 uv_MainTex : TEXCOORD0;
			};
			
			struct FragInput {
				float4 Position : SV_POSITION;
				float2	uv_MainTex : TEXCOORD0;
			};

			sampler2D _MainTex;	//	new lum
			int	GenerateRandomAlpha;
			float3 MagicNumberA;
			float3 MagicNumberB;
			float3 MagicNumberC;
						
			float fract(float x)
			{
				return x - floor(x);
				}
						
			float snoise(in float2 co){
			    return fract(sin(dot(co.xy ,float2(MagicNumberA.x,MagicNumberA.y))) * MagicNumberA.z);
			}

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
	
			float4 frag(FragInput In) : SV_Target 
			{
				float2 fragCoord = In.uv_MainTex;
				float x = snoise( fragCoord.xy * float2(cos(MagicNumberB.x),sin(MagicNumberC.x))); 
				float y = snoise( fragCoord.xy * float2(cos(MagicNumberB.y),sin(MagicNumberC.y))); 
				float z = snoise( fragCoord.xy * float2(cos(MagicNumberB.z),sin(MagicNumberC.z))); 
				float w = snoise( fragCoord.xy * float2(cos(MagicNumberB.x),sin(MagicNumberC.z))); 
				w = !GenerateRandomAlpha ? 1.0 : w;
				return float4(x,y,z,w);
			}
		ENDCG
	}
	} 
}
