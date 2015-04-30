#define InnerSampleCount	16
#define OuterSampleCount	16
#define InnerSampleWeight	0.3f
#define OuterSampleWeight	0.7f

int LEFTSHIFT(int Mask)
{
	return Mask * 2;
}

int RIGHTSHIFTONCE(int Mask)
{
	return Mask / 2;
} 

int RIGHTSHIFT(int Mask,int Iterations=1)
{
	for ( int i=0;	i<Iterations;	i++ )
		Mask = RIGHTSHIFTONCE(Mask);
	return Mask;
}


int BIT(int BitIndex)
{
	return (BitIndex==0) ? 1 : pow(2,BitIndex);
}

int OR(int a,int b)
{
	//	gr; only works if bit doesn't already exist
	return a+b;
}

int MOD(int a,int b)
{
	//	http://stackoverflow.com/questions/2761973/how-can-i-do-mod-without-a-mod-operator
	// mod = a % b
	//int c = Fix(a / b)
	//mod = a - b * c
	//return mod;
	return a % b;
}
bool HASBIT(int Mask,int BitIndex)
{
	Mask = RIGHTSHIFT( Mask, BitIndex );
	int d = MOD(Mask,2);
	return d == 1;
}



bool HASBIT0(int Mask)
{
	int d = MOD(Mask,2);
	return d == 1;
}
