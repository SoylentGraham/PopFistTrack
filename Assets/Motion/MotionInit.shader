Shader "Rewind/MotionInit" {
	Properties {
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
			

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}

			float4 frag(FragInput In) : SV_Target {
				
				return float4( tex2D( _MainTex, In.uv_MainTex ).rgb, 1.0 );
			}

		ENDCG
		}
	} 
}
