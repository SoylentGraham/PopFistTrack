Shader "Rewind/Undrag" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		UvMapTexture ("UvMapTexture", 2D) = "white" {}
	}
	SubShader {
	 Pass {
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


			sampler2D _MainTex;
			sampler2D UvMapTexture;
			
			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
			
			float4 frag(FragInput In) : SV_Target 
			{
				float4 UvMap = tex2D( UvMapTexture, In.uv_MainTex );
				float Valid = UvMap.z;
				if ( Valid < 1 )
					return float4(0,1,0,1);
					
				float2 LumUv = UvMap.xy;
				float4 OriginalLum = tex2D( _MainTex, LumUv );
				OriginalLum.w = 1.0f;
				return OriginalLum;		
			}

		ENDCG
		}
	} 
}
