Shader "Rewind/MotionFiller" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		FillRadius("FillRadius",Int) = 0
		TextureWidth("TextureWidth",Int) = 64
		TextureHeight("TextureHeight",Int) = 64
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
			int FillRadius;
			int TextureWidth;
			int TextureHeight;

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}

			float3 UnnormaliseDeltaDiff(float4 DeltaDiffw)
			{
				//	 0...1-> -0.5....0.5
				DeltaDiffw.x -= 0.5;
				DeltaDiffw.y -= 0.5;
				return DeltaDiffw.xyz;
			}
			
			float4 NormaliseDeltaDiff(float3 DeltaDiff)
			{
				//	-0.5....0.5 -> 0...1
				DeltaDiff.x += 0.5;
				DeltaDiff.y += 0.5;
				return float4( DeltaDiff.x, DeltaDiff.y, DeltaDiff.z, 1.0f );
			}
					
			float3 GetDeltaDiff(int2 SampleOffsetPixels,FragInput In)
			{
				float2 PixelsToUv = float2( 1.0/(float)TextureWidth, 1.0/(float)TextureHeight );
				float2 SampleOffsetUv = SampleOffsetPixels * PixelsToUv;
				return UnnormaliseDeltaDiff( tex2D( _MainTex, In.uv_MainTex + SampleOffsetUv ) );
			}
			
		
			float3 GetBestDeltaDiff(float3 a,float3 b)
			{
				if ( dot(a.xy,a.xy) >= dot(b.xy,b.xy) )
					return a;
				else
					return b;
			}
			

			float3 GetBestDeltaDiff(int Radius,FragInput In,float3 BestDeltaDiff)
			{
			
				//	top row
				for ( int x=-Radius;	x<=Radius;	x++ )
				{
					int y = -Radius;
					float3 RadDiff = GetDeltaDiff( int2( x,y ), In );
					BestDeltaDiff = GetBestDeltaDiff( BestDeltaDiff, RadDiff );
				}
				
				//	bottom row
				for ( int x=-Radius;	x<=Radius;	x++ )
				{
					int y = Radius;
					float3 RadDiff = GetDeltaDiff( int2( x,y ), In );
					BestDeltaDiff = GetBestDeltaDiff( BestDeltaDiff, RadDiff );
				}
				
				//	left col
				for ( int y=-Radius+1;	y<=Radius-1;	y++ )
				{
					int x = -Radius;
					float3 RadDiff = GetDeltaDiff( int2( x,y ), In );
					BestDeltaDiff = GetBestDeltaDiff( BestDeltaDiff, RadDiff );
				}
				
				//	right col
				for ( int y=-Radius+1;	y<=Radius-1;	y++ )
				{
					int x = Radius;
					float3 RadDiff = GetDeltaDiff( int2( x,y ), In );
					BestDeltaDiff = GetBestDeltaDiff( BestDeltaDiff, RadDiff );
				}
				
				return BestDeltaDiff;
			}
			
			
			
			float4 frag(FragInput In) : SV_Target 
			{
				return tex2D( _MainTex, In.uv_MainTex );
				float3 DeltaDiff = GetDeltaDiff( int2(0,0), In );
			/*
				//	search radius for more real result
				for ( int r=1;	r<=FillRadius;	r++ )
				{
					DeltaDiff = GetBestDeltaDiff( r, In, DeltaDiff );
				}
			*/
				return NormaliseDeltaDiff(DeltaDiff);	
			}

		ENDCG
		}
	} 
}
