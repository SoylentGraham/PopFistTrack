	vector2 MaxMotion = vector2( 4.f, 4.f );

float Lerp(float Time,float Min,float Max)
{
	Time = clamp( Time, 0, 1 );
	return ((Max-Min) * Time) + Min;
}
float GetTime(float Value,float Min,float Max)
{
	Value = clamp( Value, Min, Max );
	return (Value - Min) / ( Max - Min)
}

vector2 MotionToRg(vector2 Motion)
{
	//	have to fit -V...V into 0..1
	Motion.x = GetTime( Motion.x, -MaxMotion.x, MaxMotion.x );
	Motion.y = GetTime( Motion.y, -MaxMotion.y, MaxMotion.y );
	return Motion;
}

vector2 RgToMotion(vector2 Rg)
{
	//	0..1 to -V...V
	Motion.x = Lerp( Rg.x, -MaxMotion.x, MaxMotion.x );
	Motion.y = Lerp( Rg.y, -MaxMotion.y, MaxMotion.y );

	return Motion;
}