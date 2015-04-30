Shader "Rewind/UvMapUpdate" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		MotionTexture ("MotionTexture", 2D) = "white" {}
	}
	SubShader {
	
	pass
	{
		CGPROGRAM

#define DELTA_MAX	32.0f
			#pragma vertex vert
			#pragma fragment frag
	
			sampler2D _MainTex;
			sampler2D MotionTexture;
			float4 MotionTexture_TexelSize;
			const float4 InvalidColour = float4(0,1,0,1);
	
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
						
			float2 UnnormaliseDelta(float2 Delta)
			{
				Delta -= float2(0.5,0.5);
				Delta *= float2(2,2);	//	-0.5...0.5
				Delta *= float2(DELTA_MAX,DELTA_MAX);	//	-1...1
				return Delta;
			}
			
			float2 DeltaToUv(float2 Delta)
			{
				Delta = UnnormaliseDelta( Delta );
				Delta *= MotionTexture_TexelSize.xy;
				//Delta += float2(0.001f,0.001f);
				return Delta;
			}
	
			float4 frag(FragInput In) : SV_Target 
			{
				float4 DeltaDiffValid = tex2D( MotionTexture, In.uv_MainTex );
				
				if ( DeltaDiffValid.w < 1 )
				{
					//	no change
					DeltaDiffValid.xy = float2(0.5,0.5);
					/*
					float2 uv = float2(0,0);
					float Valid = 0;
					float w = 1;
					return float4( uv.x, uv.y, Valid, w );
					*/
				}
				else
				{
				//	return float4(0,0,1,1);
					}
					
				//	read from the last frame's uvmap
				//DeltaDiffValid.xy = float2(0.5,0.5);
				float2 UvMapSt = In.uv_MainTex - DeltaToUv(DeltaDiffValid.xy);
				
				float4 UvMap = tex2D( _MainTex, UvMapSt );
				return UvMap;
			}
		ENDCG
	}
	} 
}
