Shader "Rewind/SecondJoint" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		_RayTex ("_RayTex", 2D) = "white" {}
		AngleDegMin("AngleDegMin", Range(-180,180) ) = -90
		AngleDegMax("AngleDegMax", Range(-180,180) ) = 90
		MaxJointLength("MaxJointLength", Int ) = 40
		RayPad("RayPad", Int ) = 20
		RadiusMin("RadiusMin", Int ) = 2
	}
	SubShader {
	
	pass
	{
		CGPROGRAM

#define DEBUG	0
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

			sampler2D _RayTex;	//	height of mask at x
			sampler2D _MainTex;	//	original mask
			float4 _MainTex_TexelSize;
			float AngleDegMin;
			float AngleDegMax;
			int MaxJointLength;
			int RayPad;
			int RadiusMin;
			const int MinForwardLength = 1;
			
			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
		
			bool IsMask(float2 st)
			{
				//	gr: change this to a texture border to stop
				if ( st.x < 0.0f || st.x > 1.0f || st.y < 0.0f || st.y > 1.0f )
					return false;
					
				//	debug face exclusion
				if ( st.x > 0.4f && st.x < 0.6f )
					return false;
				
				float Alpha = tex2D( _MainTex, st ).a;
				return ( Alpha > 0.5f );
			}
		
			int GetRayLength(float2 StartUv,float2 AngleStep,int Border)
			{
				if( DEBUG)
					return 20;
		
				//	return 0 for immediate fail, but minimum for positive results
				if ( !IsMask( StartUv ) )
					return 0;
					
				for ( int i=1;	i<MaxJointLength;	i++ )
				{
					float2 Delta = AngleStep * (float)i;
					if ( !IsMask( StartUv + Delta ) )
						return max( (i-1)-Border, MinForwardLength );
				}
				int i = MaxJointLength;
				return max( (i-1)-Border,MinForwardLength);
			}
			
			float3 GetRayLengthPanRadius(float2 StartUv,float AngleDeg)
			{
				float2 AngleStep = float2( sin(radians( AngleDeg )), cos(radians(AngleDeg) ) );
				AngleStep = normalize( AngleStep );
				//	step needs to be in pixels!
				AngleStep *= _MainTex_TexelSize.x;	//	errr x or y... hmm kinda require square textures
				
				int ForwardLength = GetRayLength( StartUv, AngleStep, RayPad );
				
				//	calc end UV to do left&right cross
				float2 EndUv = StartUv + (AngleStep * (float)ForwardLength);
				float2 LeftStep = float2( AngleStep.y, -AngleStep.x );
				float2 RightStep = float2( -AngleStep.y, AngleStep.x );
				int LeftLength = GetRayLength( EndUv, LeftStep, 0 );
				int RightLength = GetRayLength( EndUv, RightStep, 0 );
				
				//	give radius a minimum
				LeftLength = max( RadiusMin, LeftLength );
				RightLength = max( RadiusMin, RightLength );
				
				//	left 10
				//	right 7
				//	off = -1.5 = (7-10)/2
				//float Offset = (RightLength - LeftLength) / 2.0f;
				float Offset = (LeftLength - RightLength) / 2.0f;	//	note: we mult with left, so we want left to be positive
				float Radius = (RightLength + LeftLength) / 2.0f;
				
				return float3(ForwardLength,Offset,Radius);
			}
		
			float SoyLerp(float from,float to,float step)
			{
				return ((to-from)*step) + from;
			}
					
			float4 frag(FragInput In) : SV_Target 
			{
				
				float AngleDeg = SoyLerp( AngleDegMin, AngleDegMax, In.uv_MainTex.y );
				int HeightMax = _MainTex_TexelSize.w;	//	original texture height used to normalise height
				float Heightf = tex2D( _RayTex, float2(In.uv_MainTex.x,0) ).r;
				int Height = Heightf * (float)HeightMax;

				if ( DEBUG )
					return float4(Heightf,Heightf,Heightf,Heightf);
				
				//	starting uv
				float2 StartUv = float2( In.uv_MainTex.x, Heightf );
				float3 RayLengthPanRadius = GetRayLengthPanRadius( StartUv, AngleDeg );

				float MaxJointLengthf = (float)MaxJointLength;				
				
				float LengthNorm = clamp( RayLengthPanRadius.x / MaxJointLengthf, 0, 1 );
				float PanNorm = clamp( RayLengthPanRadius.y / MaxJointLengthf, 0, 1 );
				float RadiusNorm = clamp( RayLengthPanRadius.z / MaxJointLengthf, 0, 1 );
				
				if ( DEBUG )
				{
					LengthNorm = 12.0f/255.0f;
					PanNorm = 34.0f/255.0f;
					RadiusNorm = 56.0f/255.0f;
					//Heightf = 78.0f/255.0f;
					
					//LengthNorm.x = StartUv.x;
					//PanNorm = StartUv.y;
				}
				return float4( LengthNorm, PanNorm, RadiusNorm, Heightf );
			}
		ENDCG
	}
	} 
}
