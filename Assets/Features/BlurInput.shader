Shader "Rewind/BlurInput" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		AnimateSpeed("AnimateSpeed", Range(0,1) ) = 1
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
			float Time;
			float AnimateSpeed;
			
			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
			
			
			float4 frag(FragInput In) : SV_Target 
			{
				float sinSpeedScale = AnimateSpeed/16.0f;
				float cosSpeedScale = AnimateSpeed/10.0f;
				float2 offset = float2(cos(Time*cosSpeedScale),sin(Time*sinSpeedScale));
				int x = abs(In.uv_MainTex.x+offset.x) * _MainTex_TexelSize.z;
				int y = abs(In.uv_MainTex.y+offset.y) * _MainTex_TexelSize.w;
				int xspace = 60;
				int yspace = 60;
				int Width = 20;
				int Height = 20;
				if ( (x % xspace) < Width && (y%yspace)<Height )
					return float4( 1,1,1,1 );
				else
					return float4( 0,0,0,1 );
			}

		ENDCG
		}
	} 
}
