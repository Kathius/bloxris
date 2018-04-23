module glcanvas;

public import derelict.sdl.sdl;
public import derelict.opengl.gl;
public import derelict.opengl.glu;

import std.string;

struct PointT(T)
{
	T x=0, y=0;
	PointT opMul(float scale)
	{
		return PointT(this.x*scale, this.y*scale);
	}
	PointT opMul(PointT p2)
	{
		return PointT(this.x*p2.x, this.y*p2.y);
	}
	PointT opAdd(PointT p)
	{
		return PointT(this.x + p.x, this.y + p.y);
	}
};

alias PointT!(float) Point;


class GlCanvas
{
protected:
	//	field of view => the angle our camera will see vertically
	const float fov = 90.f;

	//	distance of the near clipping plane
	const float nearPlane = .1f;

	//	distance of the far clipping plane
	const float farPlane = 100.f;
	
	int xResolution, yResolution;
	
	static int [][][char] Letters;
	static float[][][] colors = [[],
	                             /* red */
	                  		   [[1, 0, 0],[1, 0.3, 0], [1, 0, 0.3], [.8, 0.3, 0.3]],
	                  		     /* green */
	                  		   [[0, 1, 0],[0.3, 1, 0], [0, 1, 0.3], [0.3, .8, 0.3]],
	                  		     /* blue */
	                  		   [[0, 0, 1],[0, 0.3, 1], [0.3, 0, 1], [0.3, 0.3, .8]],
	                  		     /* purple */
	                  		   [[1, 0, 1],[1, .3, 1], [.7, 0, 1], [.7, .3, .7]],
	                  		     /* purple */
	                  		   [[1, 0.5, 0],[1, 0.5, 0.3], [1, 0.8, 0], [1, .8, 0.3]],
	                  		   [[0.2, 0.5, 0.2],[0.3, 0.5, 0.2], [0.2, 0.5, 0.3], [0.3, 0.5, 0.3]],
	                  		   [[0.5, 0.8, 0.2],[0.5, 0.7, 0.2], [0.5, 0.6, 0.2], [0.5, 0.5, 0.2]],
	                  		                           ];
	

public:
	

	this(int x, int y)
	{
		xResolution = x;
		yResolution = y;
	}
	
	static this()
	{
		Letters['0'] = [[1,1,1],[1,0,1],[1,0,1],[1,0,1],[1,1,1]];
		Letters['1'] = [[1],[1],[1],[1],[1]];
		Letters['2'] = [[1,1,1],[0,0,1],[1,1,1],[1,0,0],[1,1,1]];
		Letters['3'] = [[1,1,1],[0,0,1],[0,1,1],[0,0,1],[1,1,1]];
		Letters['4'] = [[1,0,1],[1,0,1],[1,1,1],[0,0,1],[0,0,1]];
		Letters['5'] = [[1,1,1],[1,0,0],[1,1,1],[0,0,1],[1,1,1]];
		Letters['6'] = [[1,1,1],[1,0,0],[1,1,1],[1,0,1],[1,1,1]];
		Letters['7'] = [[1,1,1],[0,0,1],[0,0,1],[0,0,1],[0,0,1]];
		Letters['8'] = [[1,1,1],[1,0,1],[1,1,1],[1,0,1],[1,1,1]];
		Letters['9'] = [[1,1,1],[1,0,1],[1,1,1],[0,0,1],[1,1,1]];
		
		Letters[' '] = [[0],[0],[0],[0],[0]];
		Letters[':'] = [[0],[1],[0],[1],[0]];
		Letters['.'] = [[0],[0],[0],[0],[1]];
		Letters['-'] = [[0,0],[0,0],[1,1],[0,0],[0,0]];
		
		Letters['a'] = [[0,2,0],[2,0,2],[2,2,2],[2,0,2],[2,0,2]];
		Letters['c'] = [[2,2,2],[2,0,0],[2,0,0],[2,0,0],[2,2,2]];
		Letters['e'] = [[5,5,5],[5,0,0],[5,5,0],[5,0,0],[5,5,5]];
		Letters['f'] = [[2,2,2],[2,0,0],[2,2,0],[2,0,0],[2,0,0]];
		Letters['g'] = [[2,2,2],[2,0,0],[2,2,0],[2,0,2],[2,2,2]];
		Letters['i'] = [[4,4,4],[0,4,0],[0,4,0],[0,4,0],[4,4,4]];
		Letters['l'] = [[6,0,0],[6,0,0],[6,0,0],[6,0,0],[6,6,6]];
		Letters['m'] = [[5,0,5],[5,5,5],[5,0,5],[5,0,5],[5,0,5]];
		Letters['n'] = [[5,5,5],[5,0,5],[5,0,5],[5,0,5],[5,0,5]];
		Letters['o'] = [[3,3,3],[3,0,3],[3,0,3],[3,0,3],[3,3,3]];
		Letters['p'] = [[1,1,1],[1,0,1],[1,1,1],[1,0,0],[1,0,0]];
		Letters['q'] = [[3,3,3],[3,0,3],[3,0,3],[3,3,3],[3,3,3]];
		Letters['r'] = [[4,4,4],[4,0,4],[4,4,4],[4,4,0],[4,0,4]];
		Letters['s'] = [[1,1,1],[1,0,0],[1,1,1],[0,0,1],[1,1,1]];
		Letters['t'] = [[1,1,1],[0,1,0],[0,1,0],[0,1,0],[0,1,0]];
		Letters['u'] = [[3,0,3],[3,0,3],[3,0,3],[3,0,3],[3,3,3]];
		Letters['v'] = [[7,0,7],[7,0,7],[7,0,7],[0,7,0],[0,7,0]];
		Letters['w'] = [[1,0,1],[1,0,1],[1,0,1],[1,1,1],[1,0,1]];
		Letters['x'] = [[1,0,1],[1,0,1],[0,1,0],[1,0,1],[1,0,1]];
		Letters['z'] = [[2,2,2],[0,0,2],[0,2,0],[2,0,0],[2,2,2]];
	}
	
	void SetupGl()
	{

		// switch to the projection mode matrix
		glMatrixMode(GL_PROJECTION);

		// load the identity matrix for projection
		glLoadIdentity();

		// setup a perspective projection matrix
		gluPerspective(fov, cast(float) xResolution / yResolution, nearPlane,
				farPlane);

		// switch back to the modelview transformation matrix
		glMatrixMode(GL_MODELVIEW);

		// load the identity matrix for modelview
		glLoadIdentity();
	}

	static void DrawLine(Point s, Point e)
	{
	    glBegin(GL_LINES);
	    glColor3f (1,    0,    0);
	    glVertex3f(s.x,  s.y,   -2);

	    glColor3f (0,    1,    0);
	    glVertex3f(e.x,   e.y,   -2);
	    glEnd();	
	}
	
	static void DrawText(Point pos, char[] Text, float w, uint color=0)
	{
		foreach (l; std.string.tolower(Text))
		{
			if (!(l in Letters)) throw new Exception("Letter '" ~ l ~"' not found");
			for (int i=0;i<Letters[l].length;i++)
			{
				for (int j=0;j<Letters[l][0].length;j++)
				{
					if (Letters[l][i][j])
					{
						GlCanvas.DrawSquare(pos + Point(j, -i-1)*w, w, color ? color : Letters[l][i][j]);
					}
				}
			}
			pos.x += (Letters[l][0].length+1) * w;
		}
		
	}

	static void DrawSquare(Point pos, float w, uint color=1)
	{
	    glBegin(GL_QUADS);
	    glColor3f (colors[color][0][0], colors[color][0][1], colors[color][0][2]);
	    glVertex3f(pos.x,  pos.y,   -2);

	    glColor3f (colors[color][1][0], colors[color][1][1], colors[color][1][2]);
	    glVertex3f(pos.x+w,   pos.y,   -2);

	    glColor3f (colors[color][2][0], colors[color][2][1], colors[color][2][2]);
	    glVertex3f(pos.x+w,    pos.y+w,   -2);

	    glColor3f (colors[color][3][0], colors[color][3][1], colors[color][3][2]);
	    glVertex3f(pos.x,   pos.y+w,   -2);
	    glEnd();
		
	}
	
	void Clear()
	{
		glClear(GL_COLOR_BUFFER_BIT);
	}
	void Swap()
	{
		SDL_GL_SwapBuffers();
	}
	
};