Shader "Rewind/MotionHistogram" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
	}
	SubShader {
	
	pass
	{
		CGPROGRAM
		
		//	#define UNITY_IOS

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
			float4 _MainTex_TexelSize;
			
			const bool IncludeSelf = true;
			
			#if defined(UNITY_IOS)
			const int SampleRadius = 1;
			const int HitCountMin = 4;
			#else
			int SampleRadius;
			int HitCountMin;
			#endif


			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
						
			float4 frag(FragInput In) : SV_Target 
			{
			/*
				//	each pixel(uv) represents a direction vector xy, count matches
				//	lower resolution to generate range
				//	input = 256 range
				//	output = 64 range
				//	therefore match range is +- 64/256*outputtexel
				float2 MatchDeltaMin = In.uv_MainTex;
				float2 MatchDeltaMax = In.uv_MainTex;
				
				int Matches = 0;
				
				//	integer loops can be unrolled
				for ( int y=0;	y<_MainTex_TexelSize.w;	y++ )
				for ( int x=0;	x<_MainTex_TexelSize.z;	x++ )
				{
					float2 st = _MainTex_TexelSize.xy * float2(x,y); 
					float4 DeltaDiffValid = tex2D( _MainTex, st );
					if ( DeltaDiffValid.w < 1 )
						continue;
					if ( DeltaDiffValid.xy < MatchDeltaMin )
						continue;
					if ( DeltaDiffValid.xy < MatchDeltaMax )
						continue;
				
					Matches++;
				}
				
				//	max possible is all of them
				int MaxMatches = _MainTex_TexelSize.w * _MainTex_TexelSize.z;
				//	but lets assume that doesn't happen much
				float MaxMatchesf = 0.20f * MaxMatches;
				
				float MatchesNorm = clamp( Matches / MaxMatchesf, 0, 1);
				return float4( MatchesNorm, MatchesNorm, MatchesNorm, 1 );
				*/
				return float4(1,0,0,1);
			}
		ENDCG
	}
	} 
}
