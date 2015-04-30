Shader "Rewind/Ray" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		RayPad("RayPad", Int ) = 5
	}
	SubShader {
	
	pass
	{
		CGPROGRAM
			//	http://docs.unity3d.com/Manual/SL-ShaderPrograms.html
			//	gr: gles3 doesn't work on android!
			#pragma only_renderers opengl metal gles
			#pragma vertex vert
			#pragma fragment frag
			
			#define DEBUG 0
	
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
			int RayPad;
			int Debug;

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
		
			bool IsMask(float2 st)
			{
				//	gr: change this to a texture border to stop
			//	if ( st.x < 0.0f || st.x > 1.0f || st.y < 0.0f || st.y > 1.0f )
			//		return false;
				float Alpha = tex2D( _MainTex, st ).a;
				return ( Alpha > 0.5f );
			}
			int Debug_GetColumnHeight(float s)
			{
			//	if ( s > 0.3f && s < 0.7f )
			//	return 0;
				
				//int Height = ((float)_MainTex_TexelSize.w)-1;
				int Height = 127;
				if ( Height <= 0 )
					return 55;
					
				//for ( int i=0;	i<Height;	i++)
				for ( int i=0;	i<10;	i++)
				{
					return 22;
					float t = (float)i * _MainTex_TexelSize.y;
				//	if ( !IsMask( float2(s,t) ) )
						return i+1;
					//	return max( (i-1)-RayPad,0);
				}
				return 99;
				int i = Height;
				return i+1;
				return max( (i-1)-RayPad,0);
			}			
			
			int GetColumnHeight(float s)
			{
				if ( s > 0.3f && s < 0.7f )
					return 0;
				
				int Height = ((float)_MainTex_TexelSize.w)-1;
				for ( int i=0;	i<Height;	i++)
				{
					float t = (float)i * _MainTex_TexelSize.y;
					if ( !IsMask( float2(s,t) ) )
						return max( (i-1)-RayPad,0);
				}
				int i = Height;
				return max( (i-1)-RayPad,0);
			}
							
			float4 frag(FragInput In) : SV_Target 
			{
				float HeightNorm;
				if ( DEBUG )
				{
				//int Height = GetColumnHeight( In.uv_MainTex.x );
				int Height = Debug_GetColumnHeight( 0 );
				//float HeightNorm = (float)Height / _MainTex_TexelSize.w;
				HeightNorm = (float)Height / 256.0f;
				//HeightNorm = (float)Height / 1000.0f;
				//if( Debug )
				//	HeightNorm = 120.0f/255.0f;
				}
				else
				{
					int Height = GetColumnHeight( In.uv_MainTex.x );
					HeightNorm = (float)Height / _MainTex_TexelSize.w;
				}
				
				return float4( HeightNorm, 0, 0, 1 );
			}
		ENDCG
	}
	} 
}
