Shader "Rewind/MotionAdjustSource" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		MotionTexture ("MotionTexture", 2D) = "white" {}
		Debug_ShowNoMovement("Debug_ShowNoMovement",Int) = 1
	}
	SubShader {
	 Pass {
		CGPROGRAM

			#define DELTA_MAX	32.0f

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
			float4 _MainTex_TexelSize;
			sampler2D MotionTexture;
			int Debug_ShowNoMovement;

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
		
			float2 UnnormaliseDelta(float2 Delta)
			{
				Delta -= float2(0.5,0.5);
				Delta *= float2(2,2);	//	-0.5...0.5
				Delta *= float2(DELTA_MAX,DELTA_MAX);	//	-1...1
				return Delta;
			}

			float4 frag(FragInput In) : SV_Target 
			{
				//	read motion info for this pixel
				float4 MotionDeltaDiffValid = tex2D( MotionTexture, In.uv_MainTex );
				
				//	invalid, no movement
				if ( MotionDeltaDiffValid.w < 1 )
				{
					if ( Debug_ShowNoMovement )
						return float4(0,1,0,1);
					MotionDeltaDiffValid.xy = float2(0.5,0.5);
				}
				else
					MotionDeltaDiffValid.xy = UnnormaliseDelta( MotionDeltaDiffValid.xy );
				
				//	scale to texel
				MotionDeltaDiffValid.xy *= _MainTex_TexelSize.xy;
				
				//	get new uv
				float2 SampleUv = In.uv_MainTex - MotionDeltaDiffValid.xy;
				return tex2D( _MainTex, SampleUv );
			}

		ENDCG
		}
	} 
}
