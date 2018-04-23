module block;

import glcanvas;
import std.random;

class Block
{
public:
	uint[] Shape;
	
	int Turn = 0;
	
	int Width, Height;
	
	
	this(uint[][] sh)
	{
		Height = sh.length;
		Width = sh[0].length;
		foreach (r; sh) foreach (c; r) Shape ~= c;
	}
	
	void Draw(Point pos, float Scale)
	{
		for (int i=0;i<Height;i++)
		{
			for (int j=0;j<Width;j++)
			{
				if (Shape[i*Width+j])
				{
					GlCanvas.DrawSquare(pos + Point(j, -i-1)*Scale, Scale, Shape[i*Width+j]);
				}
			}
		}
	}
	
	void RotateRight()
	{
		uint[] tmp = Shape.dup;
		
		uint k=0;
		for (int i=0;i<Width;i++)
		{
			for (int j=0;j<Height;j++)
			{
				Shape[k] = 
					tmp[Width*Height-(j+1)*Width+i];
				k++;
			}
		}
		uint tmp2=Width;
		Width=Height;
		Height=tmp2;
	}

	void RotateLeft()
	{
		for (auto i=0;i<3;i++) RotateRight();
	}
	
	uint[] GetCurrentShape()
	{
		return Shape;
	}
	
}

