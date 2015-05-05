Shader "Custom/MakeHomographys" {
	Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		RandomTexture ("RandomTexture", 2D) = "white" {}
		
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

			sampler2D _MainTex;	
			float4 _MainTex_TexelSize;	
			sampler2D RandomTexture;

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
	
			float3x3 CalculateHomography()
			{
				float3x3 Homography;
				return Homography;
			}
			
			int CountInliers(float3x3 Homography)
			{
				return 4;
			}
				
			float4 frag(FragInput In) : SV_Target 
			{
				int InputIndex = (int)(In.uv_MainTex.x * _MainTex_TexelSize.z);
				
				float3x3 Homography = CalculateHomography();
				
				//	now which index do we want?
				float4 Output;
				int OutputIndex = (int)(In.uv_MainTex.y * _MainTex_TexelSize.w);
				if ( OutputIndex == 0 )
				{
					Output.xyz = Homography[0].xyz;
					Output.w = 1.0;
				}
				else if ( OutputIndex == 1 )
				{
					Output.xyz = Homography[1].xyz;
					Output.w = 1.0;
				}
				else if ( OutputIndex == 2 )
				{
					//	calc inliers
					int Inliers = CountInliers( Homography );
					
					Output.xyz = Homography[2].xyz;
					Output.w = Inliers / 4;
				}
					
				return Output;
			}
		ENDCG
	}
	} 
}
