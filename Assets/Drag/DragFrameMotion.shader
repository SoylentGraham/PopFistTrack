Shader "Rewind/FrameMotion" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		Prev_MainTex ("Prev_MainTex", 2D) = "white" {}
		DiffTolerance ("DiffTolerance", range(0,1) )= 0.03
		FavourSmallerRadDiff("FavourSmallerRadDiff", range(0,1) ) = 0.015
		DiffRadius("DiffRadius",Int) = 3
		RadStep("RadStep",Int) = 2
		MinDeltaLength("MinDeltaLength", Int ) = 5
		Debug_AmplifyDelta("Debug_AmplifyDelta", Int )=0
	}
	SubShader {
	 Pass {
		CGPROGRAM

			#define DIFFRADIUS_MAX	8
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
			sampler2D Prev_MainTex;
			float DiffTolerance;
			float FavourSmallerRadDiff;
			int DiffRadius;			
			int RadStep;
			float4 _MainTex_TexelSize;
			int MinDeltaLength;
			int Debug_AmplifyDelta;

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
			
			float4 GetDeltaDiff(float BaseLum,int2 SampleOffsetPixels,FragInput In,int Radius)
			{
				float2 SampleOffsetUv = SampleOffsetPixels * _MainTex_TexelSize.xy;
				float PrevLum = tex2D( Prev_MainTex, In.uv_MainTex + SampleOffsetUv ).r;
				float Diff = BaseLum - PrevLum;
				return float4( SampleOffsetPixels.x, SampleOffsetPixels.y, Diff, Radius );
			}
			
			float4 GetBestDeltaDiff(float4 a,float4 b)
			{
				float LumDiffDiff = abs(a.z) - abs(b.z);

				//	on ultra minor differences, favour smaller movement				
//				if ( abs(LumDiffDiff) < FavourSmallerRadDiff )
//					return ( length(a.xy) < length(b.xy) ) ? a : b;
				if ( LumDiffDiff == 0 )
				{
					if ( length(a.xy) <= length(b.xy) ) return a;
					return b;
				}				
				
				if ( LumDiffDiff < 0 )
					return a;
				else
					return b;
			}
			
			float4 GetRadiusBestDeltaDiff(float BaseLum,int Radius,FragInput In,float4 BestDeltaDiff)
			{
				//	top & bottom row
				for ( int x=-Radius;	x<=Radius;	x++ )
				{
					BestDeltaDiff = GetBestDeltaDiff( BestDeltaDiff, GetDeltaDiff( BaseLum, int2( x,-Radius ), In, Radius ) );
					BestDeltaDiff = GetBestDeltaDiff( BestDeltaDiff, GetDeltaDiff( BaseLum, int2( x,Radius ), In, Radius ) );
	
					if ( x == -Radius || x == Radius )
						continue;
					BestDeltaDiff = GetBestDeltaDiff( BestDeltaDiff, GetDeltaDiff( BaseLum, int2( -Radius,x ), In, Radius ) );
					BestDeltaDiff = GetBestDeltaDiff( BestDeltaDiff, GetDeltaDiff( BaseLum, int2( Radius,x ), In, Radius ) );
				}
					
				return BestDeltaDiff;
			}
			
			float2 NormaliseDelta(float2 Delta)
			{
				Delta /= float2(DELTA_MAX,DELTA_MAX);	//	-1...1
				Delta /= float2(2,2);	//	-0.5...0.5
				Delta += float2(0.5,0.5);
				return Delta;
			}
			
			float4 frag(FragInput In) : SV_Target 
			{
				float4 InvalidDiffTolerance = float4(1,0,1,0);
				float4 InvalidMinDelta = float4( 0, 0, 1, 0 );
				float ValidMotion = 1;
				
				float LumNew = tex2D( _MainTex, In.uv_MainTex ).r;
				float BaseLum = LumNew;

				//	initial value
				float4 DeltaDiff = GetDeltaDiff( BaseLum, int2(0,0), In, 0 );
			
				//	search radius for best result
				for ( int r=1;	r<=DIFFRADIUS_MAX;	r++ )
				{
					if ( r <= DiffRadius )
						DeltaDiff = GetRadiusBestDeltaDiff( BaseLum, r+RadStep, In, DeltaDiff );
				}				
					
				//	normalise (-r...r) to 0...1
				float2 Delta = DeltaDiff.xy;			//	-r...r
				
				if ( length(Delta) < MinDeltaLength )
					return InvalidMinDelta;
				
				//	gr: test, amplify movement to max
				if ( Debug_AmplifyDelta )
				{
					if ( Delta.x > 0 )	Delta.x = DELTA_MAX;
					if ( Delta.x < 0 )	Delta.x = -DELTA_MAX;
					if ( Delta.y > 0 )	Delta.y = DELTA_MAX;
					if ( Delta.y < 0 )	Delta.y = -DELTA_MAX;
				}
				
				Delta = NormaliseDelta( Delta);
			
					
				float Diff = abs(DeltaDiff.z);
				//float Diff = 0;
					
				//	not valid
				if ( abs(Diff) > DiffTolerance )
					return InvalidDiffTolerance;

				return float4( Delta.x, Delta.y, Diff, ValidMotion );
			}

		ENDCG
		}
	} 
}
