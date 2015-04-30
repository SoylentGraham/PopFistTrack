Shader "Rewind/InputMaskTest" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
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
			float4 _MainTex_TexelSize;

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
		
			bool IsMask(float2 st)
			{
				float Alpha = tex2D( _MainTex, st ).r;
				return ( Alpha < 0.7f );
			}
			
			int GetColumnHeight(float s)
			{
				int Height = _MainTex_TexelSize.w;
				for ( int i=1;	i<Height;	i++)
				{
					float t = (float)i * _MainTex_TexelSize.y;
					if ( !IsMask( float2(s,t) ) )
						return (i-1);
				}
				return Height;
			}
							
			float4 frag(FragInput In) : SV_Target 
			{
				bool ismask = IsMask( In.uv_MainTex );
				return float4( ismask?1:0, ismask?1:0, ismask?1:0, 1 );
			}
		ENDCG
	}
	} 
}
