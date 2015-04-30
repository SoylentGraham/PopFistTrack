Shader "Rewind/AlphaFiller" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		SampleRadius("SampleRadius", Int ) = 2
		HitCountMin("HitCountMin", Int ) = 7
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
			
			bool HasHit(FragInput In,int2 offi)
			{
				float2 offf = offi * _MainTex_TexelSize.xy;
				float2 uv = In.uv_MainTex + offf;
				float Alpha = tex2D( _MainTex, uv ).w;
				return Alpha > 0.1f;
			}
			
			int GetRadiusHitCount(int Radius,FragInput In)
			{
				int HitCount = 0;
			
				//	top & bottom row
				for ( int x=-Radius;	x<=Radius;	x++ )
				{
					HitCount += HasHit( In, int2( x,-Radius ) );
					HitCount += HasHit( In, int2( x,Radius ) );
					
					if ( x == -Radius || x == Radius )
					continue;
					HitCount += HasHit( In, int2( -Radius,x ) );
					HitCount += HasHit( In, int2( Radius,x ) );
				}
							
				return HitCount;
			}
			
			int GetSampleTestCount(int Radius)
			{
				int TotalTests = 0;
				for ( int i=1;	i<Radius;	i++ )
					TotalTests += (i*2) + (i*2) + ((i*2)-2) + ((i*2)-2) + 4; 
				return TotalTests;
			}
							
			float4 frag(FragInput In) : SV_Target 
			{
				float4 Sample = tex2D( _MainTex, In.uv_MainTex );
			
				int HitCount = (IncludeSelf && Sample.w>0) ? 1 : 0;
				for ( int r=1;	r<=SampleRadius;	r++ )
					HitCount += GetRadiusHitCount(r, In );
			
				Sample.w = ( HitCount >= HitCountMin ) ? 1 : 0;
				return Sample;
			}
		ENDCG
	}
	} 
}
