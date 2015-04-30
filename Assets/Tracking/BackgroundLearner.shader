Shader "Rewind/BackgroundLearner" {
	Properties {
		_MainTex ("_MainTex", 2D) = "white" {}
		LastBackgroundTex ("LastBackgroundTex", 2D) = "white" {}
		Init	("Init", Int ) = 1
		LumDiffMax("LumDiffMax",Float) = 0.20
		NewLumInfluence("NewLumInfluence",Float) = 1.0

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

			int Init;
			sampler2D _MainTex;	//	new lum
			sampler2D LastBackgroundTex;
			const int AgeMax = 20;
			float LumDiffMax;
			float NewLumInfluence;
			const bool SquareScore = true;
			const bool AgeSlowly = true;

			FragInput vert(VertexInput In) {
				FragInput Out;
				Out.Position = mul (UNITY_MATRIX_MVP, In.Position );
				Out.uv_MainTex = In.uv_MainTex;
				return Out;
			}
			
			float Lerp(float Min,float Max,float Time)
			{
				return Min + (( Max - Min )* Time);
			}
			
			float4 MakeLumTruthAge(float Lum,float Truth,int Age)
			{
				Truth = clamp( Truth, 0, 1 );
				//	lum is lum
				//	truth is 0..1 (integrety)
				//	age is frames/max frames
				float Agef = (float)Age / (float)AgeMax;
				Agef = clamp( Agef, 0, 1 );
				return float4(Lum,Truth,Agef,1).xyzw;
			}

			float4 GetLumTruthAge(float2 Uv)
			{
				float4 LumTruthAge = tex2D( LastBackgroundTex, Uv ).xyzw;
				LumTruthAge.z *= (float)AgeMax;
				return LumTruthAge;
			}

			float4 InitLumTruthAge(FragInput In)
			{
				float NewLum = tex2D( _MainTex, In.uv_MainTex ).r;
					
				int Age = 1;
				float FrameDelta = 1.0f / (AgeSlowly ? (float)AgeMax : (float)Age);
				return MakeLumTruthAge( NewLum, FrameDelta, Age );
			}
			
			float4 UpdateLumTruthAge(FragInput In)
			{
				float4 OldLumTruthAge = GetLumTruthAge(In.uv_MainTex);
				float NewLumSample = tex2D( _MainTex, In.uv_MainTex ).r;

				//	get score of this lum
				float OldLum = OldLumTruthAge.x;
				float LumDiff = abs(NewLumSample - OldLum);
				float LumScore = 1.0f - ( clamp( LumDiff / LumDiffMax, 0, 1 ) );
				if ( SquareScore )
					LumScore *= LumScore;
				bool BadLum = (LumDiff / LumDiffMax) >= 1.0f;
				
				float OldTruth = OldLumTruthAge.y;
				float NewTruth = OldTruth;
				
				//	use agemax for slow build up, use .z for very fast learn
				int Age = max(1,OldLumTruthAge.z);
				float FrameDelta = 1.0f / (AgeSlowly ? (float)AgeMax : (float)Age);
				
				//	if lum score is bad, we want to decrease the truth ("this pixel is noisy")
				if ( BadLum )
				{
					//	lose score fast
					NewTruth -= FrameDelta;
				}
				else
				{
					//	gain score slower (using squared score)
					NewTruth += LumScore * FrameDelta;
				}

				float NewWeight = (LumScore * (FrameDelta*NewLumInfluence)) * (1.0 - NewTruth);
				float OldWeight = 1.0f - NewWeight;
				
				float NewLum = (NewLumSample*NewWeight) + (OldLum*OldWeight);
								
				int NewAge = OldLumTruthAge.z + 1;
				
				return MakeLumTruthAge( NewLum, NewTruth, NewAge );
			}
						
			float4 frag(FragInput In) : SV_Target 
			{
				if ( Init != 0 )
					return InitLumTruthAge(In);
				else
					return UpdateLumTruthAge(In);
			}
		ENDCG
	}
	} 
}
