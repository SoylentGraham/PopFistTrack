Shader "Rewind/MakeFeatures" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		InnerRadius("InnerRadius",Range(1,20)) = 2
		OuterRadius("OuterRadius",Range(1,20)) = 4
		BrighterTolerance("BrighterTolerance",Range(0,1)) = 0.10
		InvertLum("InvertLum", Int ) = 0
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
			float InnerRadius;
			float OuterRadius;
			float BrighterTolerance;
			bool InvertLum;
			
			
			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
			
		
			float2 GetRingSampleOffsetPx(int Index,int Max,float Radius)
			{
				float t = Index / (float)Max;
				float rad = radians( 360.f * t );
				float x = cos( rad ) * Radius;
				float y = sin( rad ) * Radius;
				return float2(x,y);
			}
			
				
			float3 GetSampleOffsetPx(int Index)
			{
				/*
				//	gr: make 2 rings, inner and outer
				int InnerSamples = (mSampleCount / 3) * 1;
				float InnerRadius = mRadius / 2.f;
				CalculateOffsets( mSampleOffsets, InnerSamples, InnerRadius );

				int OuterSamples = (mSampleCount / 3) * 2;
				float OuterRadius = mRadius / 1.f;
				CalculateOffsets( mSampleOffsets, OuterSamples, OuterRadius );
				*/
				if ( Index < InnerSampleCount )
				{
					float2 Offset = GetRingSampleOffsetPx( Index, InnerSampleCount, InnerRadius );
					return float3( Offset.x, Offset.y, 1 );
				}
				else if ( Index < InnerSampleCount+OuterSampleCount )
				{
					float2 Offset = GetRingSampleOffsetPx( Index-InnerSampleCount, OuterSampleCount, OuterRadius );
					return float3( Offset.x, Offset.y, 1 );
				}
				else
				{
					//	index out of range
					return float3( 0, 0, 0 );
				}
			}
			
			float GetLumAtOffset(float2 UvOrigin,float2 UvOffset)
			{
				float lum = tex2D( _MainTex, UvOrigin + UvOffset.xy ).r;
				return InvertLum ? 1-lum : lum;
			}

			float GetLum(int Index,float2 UvOrigin)
			{
				float3 UvOffset = GetSampleOffsetPx( Index );
				if ( UvOffset.z < 1 )
					return 2;
				return GetLumAtOffset( UvOrigin, UvOffset.xy * _MainTex_TexelSize.xy );
			}
			
			float4 frag(FragInput In) : SV_Target 
			{
				//	get intensity of root pixel with a tolerance so anything a little darker counts as brighter
				float BaseIntensity = GetLumAtOffset(In.uv_MainTex,float2(0,0)) - BrighterTolerance;
	
				int Bits07 = 0;
				int Bits815 = 0;
				int Bits1623 = 0;
				int Bits2431 = 0;
				
				for ( int i=0;	i<32;	i++ )
				{
					float Intensity = GetLum( i, In.uv_MainTex );
	
					//	set bit
					bool SetBit = ( Intensity >= BaseIntensity );
					if ( !SetBit )
						continue;
				
					//	or with accumulating bit mask					
					if ( i < 8 )
						Bits07 = OR( Bits07, BIT(i-0) );
					else if ( i < 16 )
						Bits815 = OR( Bits815, BIT(i-8) );
					else if ( i < 24 )
						Bits1623 = OR( Bits1623, BIT(i-16) );
					else //if ( i < 32 )
						Bits2431 = OR( Bits2431, BIT(i-24) );
				}
				
				//	write bit mask to colour
			//	return float4(1,1,1,1);
				return float4( Bits07 / 255.0f, Bits815 / 255.0f, Bits1623 / 255.0f, Bits2431 / 255.0f );
			}

		ENDCG
		}
	} 
}
