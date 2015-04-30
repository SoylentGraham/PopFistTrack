Shader "Rewind/UvMapInit" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
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

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
							
			float4 frag(FragInput In) : SV_Target 
			{
				float2 OriginalUv = In.uv_MainTex;
				float w = 1;
				float Valid = 1;
				return float4( OriginalUv.x,OriginalUv.y,Valid,w);
			}
		ENDCG
	}
	} 
}
