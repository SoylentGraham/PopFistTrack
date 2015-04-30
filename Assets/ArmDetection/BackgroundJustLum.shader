Shader "Rewind/BackgroundJustLum" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		TruthMin("TruthMin", Float ) = 0.41
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

			sampler2D _MainTex;	//	new lum
			float TruthMin;

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
		
							
			float4 frag(FragInput In) : SV_Target 
			{
				float Lum = tex2D( _MainTex, In.uv_MainTex ).x;
				float Truth = tex2D( _MainTex, In.uv_MainTex ).y;
				
				/*
				//	if truth is low, discard
				//	no discard texture->texture, no alpha
				bool Discard = Truth < TruthMin;
			
				if ( Discard )
					return float4(1,0,0,0);
				*/
				bool Discard = false;
				return float4( Lum, 0, 0, Discard?0.0:1.0 );
			}
		ENDCG
	}
	} 
}
