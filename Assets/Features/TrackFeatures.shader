Shader "Rewind/TrackFeatures" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		FeaturesPrev ("FeaturesPrev", 2D) = "white" {}
		_SampleRadius("SampleRadius",Int) = 4
		SampleRadiusStep("SampleRadiusStep",Range(1,10) ) = 1
		MaxCommonHitCount("MaxCommonHitCount",Range(1,40)) = 3	//	over this and we disregard this feature as non-unique
		MinScore("MinScore", Range(0,1)) = 0.70
		CommonMinScore("CommonMinScore", Range(0,1)) = 0.90
		gUseDebugResults("UseDebugResults", Int ) = 0
	}
	SubShader {
	 Pass {
		CGPROGRAM

			#include "PopCommon.cginc"

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
			sampler2D FeaturesPrev;
			float4 FeaturesPrev_TexelSize;
			int _SampleRadius;
			const int SampleRadius = max( 0, min( 10, _SampleRadius ) );
			int MaxCommonHitCount;
			float MinScore;
			float CommonMinScore;
			int SampleRadiusStep;
			int gUseDebugResults;
			
			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}

			int GetMatchingBitCount(int a,int b,int Elements)
			{
				int MatchCount = 0;
				for ( int i=0;	i<Elements;	i++ )
				{
					MatchCount += ( HASBIT0(a) == HASBIT0(b) ) ? 1 : 0;
					//	shift down
					a = RIGHTSHIFTONCE(a);
					b = RIGHTSHIFTONCE(b);
				}
				return MatchCount;
			}
					
			
			float GetFeatureScore(int2 FeatureA,int2 FeatureB)
			{
				//	count matching bits
				//	todo: rotate ring by shifting/rolling
				int MatchInner = GetMatchingBitCount( FeatureA.x, FeatureB.x, InnerSampleCount );
				int MatchOuter = GetMatchingBitCount( FeatureA.y, FeatureB.y, OuterSampleCount );
				float ScoreWeightInner = InnerSampleWeight;
				float ScoreWeightOuter = OuterSampleWeight;
				float Score = 0.0f;
				Score += (MatchInner/(float)InnerSampleCount) * ScoreWeightInner;
				Score += (MatchOuter/(float)OuterSampleCount) * ScoreWeightOuter;
				return Score;
			}

			int2 GetFeature2(float4 Feature4)
			{
				int FeatureInner = 0;
				int FeatureOuter = 0;
				FeatureInner = OR( FeatureInner, Feature4.x * 255.f * 1.0f );
				FeatureInner = OR( FeatureInner, Feature4.y * 255.f * 256.0f );	//	shifted by 8
				FeatureOuter = OR( FeatureOuter, Feature4.z * 255.f * 1.0f );
				FeatureOuter = OR( FeatureOuter, Feature4.w * 255.f * 256.0f );	//	shifted by 8
				return int2(FeatureInner,FeatureOuter);
			}
						
			int2 GetPrevFeature(float2 Uv,int2 Offset)
			{
				Uv += Offset * FeaturesPrev_TexelSize.xy;
				float4 Feature4 = tex2D( FeaturesPrev, Uv );
				return GetFeature2( Feature4 );
			}
			
			int2 GetNewFeature(float2 Uv,int2 Offset)
			{
				Uv += Offset * _MainTex_TexelSize.xy;
				float4 Feature4 = tex2D( _MainTex, Uv );
				return GetFeature2( Feature4 );
			}
			
			float4 frag(FragInput In) : SV_Target 
			{
				bool UseDebugResults = (gUseDebugResults!=0);
				float4 Result_TooManyHits = float4( 0,0,1,UseDebugResults?1:0 );
				float4 Result_NoHits = float4( 1,0,0,UseDebugResults?1:0 );
				float4 Result_Valid = float4( 0,1,0,1 );
				
				int2 Feature = GetPrevFeature( In.uv_MainTex, int2(0,0) );
				//	todo: offset this with prediction from kalman or accellerometer or gyro
				float2 SampleOrigin = In.uv_MainTex;
				
				float2 BestIndex = int2(0,0);
				float BestScore = -1;
				float BestDist = 1000.0f;
				int CommonHitCount = 0;
				
				for ( int y=-SampleRadius;	y<=SampleRadius;	y+=max(1,SampleRadiusStep) )
				for ( int x=-SampleRadius;	x<=SampleRadius;	x+=max(1,SampleRadiusStep) )
				{
					int2 MatchFeature = GetNewFeature( SampleOrigin, int2(x,y) );
					float Score = GetFeatureScore( Feature, MatchFeature );
					if ( Score < MinScore )
						continue;
						
					//	disregard if we have loads above a common score (eg, loads over 95%, the feature must be common)
					if ( Score >= CommonMinScore )
					{
						CommonHitCount++;
						if ( CommonHitCount >= MaxCommonHitCount )
							return Result_TooManyHits;
					}

					//if ( Score < BestScore )
					//	continue;
						
					float Dist = length(float2(x,y));
					
					if ( Dist < BestDist )
					{					
						BestDist = Dist;					
						BestScore = Score;
						BestIndex = float2(x,y);
					}
				}

				
				if ( BestScore < 0 )
					return Result_NoHits;
					
				//	gr: write UV so we don't need to normalise & unnormalise the values (to cope with negatives)
				float2 MatchUvDelta = BestIndex*_MainTex_TexelSize.xy;
				//float2 MatchUv = clamp( SampleOrigin + MatchUvDelta, 0, 1 );
				float2 MatchUv = SampleOrigin + MatchUvDelta;
				return UseDebugResults ? Result_Valid : float4( MatchUv.x, MatchUv.y, BestScore, 1 );
				//return float4( MatchUv.x, MatchUv.y, BestScore, 1 );
			}

		ENDCG
		}
	} 
}