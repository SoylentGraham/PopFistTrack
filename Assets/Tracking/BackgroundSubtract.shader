Shader "Rewind/BackgroundSubtract" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		BackgroundTex ("LastBackgroundTex", 2D) = "white" {}
		BadTruth_LumDiff("BadTruth_LumDiff", Float ) = 0.60
		GoodTruth_LumDiff("GoodTruth_LumDiff", Float ) = 0.10
		TruthMin("TruthMin", Float ) = 0.01
	}
	SubShader {
	
	pass
	{
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

			float BadTruth_LumDiff;
			float GoodTruth_LumDiff;
			float TruthMin;
			sampler2D _MainTex;	//	live
			sampler2D LastBackgroundTex;

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
						
			float4 frag(FragInput In) : SV_Target 
			{
				//	get input lum
				float LiveLum = tex2D( _MainTex, In.uv_MainTex ).x;
				
				float BgLum =  tex2D( LastBackgroundTex, In.uv_MainTex ).x;
				float BgTruth = tex2D( LastBackgroundTex, In.uv_MainTex ).y;
		
				//	more accurate background, lower the tolerance
				float DiffMin = lerp( BadTruth_LumDiff, GoodTruth_LumDiff, BgTruth );

				bool IsForeground = true;
				
				//	very similar to background, and we trust background
				if ( abs(LiveLum-BgLum) < DiffMin && BgTruth > TruthMin )
					IsForeground = false;
				
				return float4( LiveLum, LiveLum, LiveLum, IsForeground ? 1 : 0 );
			}
		ENDCG
	}
	} 
}
