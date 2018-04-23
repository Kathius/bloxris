module playfield;

import glcanvas;
import gameengine.controller;
public import block;
import constants;
import derelict.sdl.sdl;

import std.random;
import std.stdio;

class PlayfieldView : View
{
protected:
	Playfield m;
	
	Point Position;
	float Scale;
	int displayed_score;
	
	struct FlyingScore {uint amount; Point pos; int dir;};
	FlyingScore[] flying_scores;
	
	
public:
	this(Playfield pf, Point pos, float s)
	{
		Position = pos;
		Scale = s;
		m = pf;
		m.AddScoreRaisedHandler(&onScoreRaised);
	}
	
	void onScoreRaised(uint amount)
	{
		if (amount >= 100)
		{
			flying_scores ~= FlyingScore(amount, Point(-2.5 + (std.random.rand()%100.0)/50, -1.5), 0);
		}		
	}
	
	void Draw()
	{
		auto lu = Point(Position.x, Position.y + m.Size.y*Scale);
		auto ru = Point(Position.x + m.Size.x*Scale, Position.y + m.Size.y*Scale);
		auto lb = Position;
		auto rb = Point(Position.x + m.Size.x*Scale, Position.y);

		GlCanvas.DrawLine(lu, ru);
		GlCanvas.DrawLine(lb, rb);
		GlCanvas.DrawLine(lb, lu);
		GlCanvas.DrawLine(rb, ru);
		
		for (auto i=0;i<m.Size.y;i++)
		{
			for (auto j=0;j<m.Size.x;j++)
			{
				if (m.m[j + i*cast(int)m.Size.x]) DrawFieldSquare(Point(j, i), m.m[j + i*cast(int)m.Size.x]);
			}
		}
		
		m.CurrentBlock.Draw(GetTranslatedPoint(m.CurrentPosition+Point(0, 0)), Scale);
		m.NextBlock.Draw(GetTranslatedPoint(Point(m.Size.x+2, m.Size.y-5)), Scale);
		
		GlCanvas.DrawText(Point(0, 1.5), "score: "~std.string.toString(displayed_score), .05);
		GlCanvas.DrawText(Point(0, 1.2), "level: "~std.string.toString(m.Level), .05);
		GlCanvas.DrawText(Point(0, 0.9), "lines: "~std.string.toString(m.LinesTotal), .05);
		
		foreach (score; flying_scores)
		{
			GlCanvas.DrawText(score.pos, std.string.toString(score.amount), .02);
		}
		
		if (m.Paused) GlCanvas.DrawText(Point(-1.4, .4), "pause", .15);	
	}

	void DrawFieldSquare(Point pos, uint color=1)
	{
		GlCanvas.DrawSquare(GetTranslatedPoint(pos + Point(0, 1)), Scale, color);
	}
	
	void onTick()
	{
		if (displayed_score+10 < m.Score) displayed_score += 10;
		else displayed_score = m.Score;
		
		for (uint iScore=0; iScore<flying_scores.length; iScore++)
		{
			flying_scores[iScore].pos.y += .005;
			if (flying_scores[iScore].dir % 100 < 50) flying_scores[iScore].pos.x -= .005;
			else if (flying_scores[iScore].dir % 100 >= 50) flying_scores[iScore].pos.x += .005;
			flying_scores[iScore].dir++;
			
			
			if (flying_scores[iScore].pos.y >= 1.5)
			{
				flying_scores[iScore] = flying_scores[length-1];
				flying_scores.length = flying_scores.length-1;
			}
		}
	}
	
	Point GetTranslatedPoint(Point p)
	{
		return p*Scale*Point(1, -1) + Point(Position.x, Position.y + m.Size.y*Scale);
	}	
}

class Playfield : Model
{
protected:
	Point Size; 
	uint[] m;
	Block CurrentBlock;
	Point CurrentPosition;
	
	auto MoveDirection = Point(0, 0);
	int MoveDelay = 0;
	
	int Score = 0;
	int Level = 1;
	int LinesTotal = 0;
	
	int Speed = 100;
	bool Paused = false;
	bool shall_wait = false;
	static uint[][][][TILESETS] Tilesets;
	uint[][][] Blocks;
	
	Block NextBlock;
	
	ScoreRaisedHandler[] score_raised_handlers;

public:
	typedef void delegate(uint) ScoreRaisedHandler;

public:

	void AddScoreRaisedHandler(ScoreRaisedHandler h)
	{
		score_raised_handlers ~= h;
	}

	static this()
	{
		 Tilesets[TILESETS.NORMAL] =[ [[0,1,0],[1,1,1]],
				                	  [[2,2],[2,2]],
				                	  [[3,0],[3,3],[0,3]],
				                	  [[0,4],[4,4],[4,0]],
				                	  [[5],[5],[5],[5]],
				                	  [[6, 6],[0, 6],[0, 6]],
				                	  [[7, 7],[7, 0],[7, 0]] ];

		Tilesets[TILESETS.ADVANCED] = [ [[1,1,1],[1,0,1]],
		                                [[2,0,2],[0,2,0],[2,0,2]],
		                                [[0,3,0],[3,3,3],[0,3,0]],
		                                [[4,0,0],[4,4,4],[4,0,0]],
		                                [[5,0,5],[5,0,5],[0,5,0]],
		                                [[6,6,0],[6,6,6]],
		                                [[7,7,7,7,7]]
		                                ];	
	}
	this(Point size, TILESETS tileset=TILESETS.NORMAL)
	{
		Size = size;
		for (uint i=0;i<Size.x*Size.y;i++) m ~= 0;
		
		Blocks = Tilesets[tileset];
		
		CreateNewBlock();
	}
	
	uint GetScore()
	{
		return Score;
	}
	
	void Wait()
	{
		shall_wait = true;
	}
	
	void Continue()
	{
		shall_wait = false;
	}
	
	void onTick()
	{
		static uint iTick = 0;
		if (Paused || shall_wait) return;

		iTick++;
		MoveDelay--;
		
		if (MoveDelay <= 0 && iTick % 5 == 0) MoveBlock(MoveDirection);
		if (iTick % Speed == 0) ForceDown();
	}
	void onKeyDown(SDLKey key)
	{
		switch (key)
		{
		case SDLK_LEFT:
			if (Paused) break;
			MoveDelay = 20;
			MoveDirection.x = -1;
			MoveBlock(Point(-1, 0));
			break;
		case SDLK_RIGHT:
			if (Paused) break;
			MoveDelay = 20;
			MoveDirection.x = 1;
			MoveBlock(Point(1, 0));
			break;
		case SDLK_DOWN:
			if (Paused) break;
			MoveDelay = 20;
			MoveDirection.y = 1;
			MoveBlock(Point(0, 1));
			break;
		case SDLK_p:
			Paused = !Paused;
			break;
		case SDLK_z:
			if (Paused) break;
			RotateLeft();
			break;
		case SDLK_x:
			if (Paused) break;
			RotateRight();
			break;
		case SDLK_ESCAPE:
			SDL_Event ev;
			ev.type = SDL_USEREVENT;
			ev.user.code = BLOXEV.GAMEOVER;
			SDL_PushEvent(&ev);
			break;
		default: break;
		}
	}
	
	void onKeyUp(SDLKey key)
	{
		switch (key)
		{
		case SDLK_LEFT:
			if (MoveDirection.x == -1) MoveDirection.x = 0;
			break;
		case SDLK_RIGHT:
			if (MoveDirection.x == 1) MoveDirection.x = 0;
			break;
		case SDLK_DOWN:
			if (MoveDirection.y == 1) MoveDirection.y = 0;
			break;
		case SDLK_UP:
			if (MoveDirection.y == -1) MoveDirection.y = 0;
			break;
		default: break;
		}		
	}
	
	void CreateNewBlock()
	{
		if (!NextBlock) NextBlock = new Block(Blocks[rand()%Blocks.length]);
		
		CurrentBlock = NextBlock;
		
		NextBlock = new Block(Blocks[rand()%Blocks.length]);
		uint r = rand()%4;
		while (r--) NextBlock.RotateRight();
		
		CurrentPosition = Point(cast(uint)(Size.x-CurrentBlock.Width)/2, 0);
		
		MoveDelay = 20;
		
		if (DoesCollide(CurrentPosition))
		{
			SDL_Event ev;
			ev.type = SDL_USEREVENT;
			ev.user.code = BLOXEV.GAMEOVER;
			SDL_PushEvent(&ev);
		}
	}
	void MoveBlock(Point dir)
	{
		if (!DoesCollide(CurrentPosition + Point(dir.x, 0))) CurrentPosition.x += dir.x;
		if (!DoesCollide(CurrentPosition + Point(0, dir.y))) CurrentPosition.y += dir.y;
		else FixBlock();
	}
	void RotateLeft()
	{
		CurrentBlock.RotateLeft();
		if (!DoesCollide(CurrentPosition)) return;
		for (int i=1;i<=CurrentBlock.Width-CurrentBlock.Height;i++)
		{
			if (!DoesCollide(CurrentPosition + Point(i, 0)))
			{
				CurrentPosition.x += i;
				return;
			}
			if (!DoesCollide(CurrentPosition + Point(-i, 0)))
			{
				CurrentPosition.x -= i;
				return;
			}
		}
		CurrentBlock.RotateRight();
		
	}
	void RotateRight()
	{
		CurrentBlock.RotateRight();
		if (!DoesCollide(CurrentPosition)) return;
		for (int i=1;i<=CurrentBlock.Width-CurrentBlock.Height;i++)
		{
			if (!DoesCollide(CurrentPosition + Point(i, 0)))
			{
				CurrentPosition.x += i;
				return;
			}
			if (!DoesCollide(CurrentPosition + Point(-i, 0)))
			{
				CurrentPosition.x -= i;
				return;
			}
		}
		CurrentBlock.RotateLeft();
	}
	void ForceDown()
	{
		if (CurrentPosition.y + 1 + CurrentBlock.Height > Size.y || DoesCollide(CurrentPosition + Point(0, 1)))
		{
			FixBlock();
		}else
		{
			CurrentPosition.y++;
		}
	}
	
	void onLinesComplete(uint n)
	{
		static int [] scores = [10, 100, 250, 500, 1000, 2000, 5000];
		RaiseScore(scores[n]);
		LinesTotal += n;
	}
	
	void RaiseScore(int amount)
	{
		static int [] levelscores = [0, 500, 1500, 3500, 6000, 10000, 17500, 30000, 50000, 75000, 100000, 150000];
		
		int real_score = cast(int)(amount * (1.0+(Level-1)*.5));

		Score += real_score;

		if (Level == levelscores.length) return;
		
		while (Score >= levelscores[Level]*Size.x/12) RaiseLevel();
		
		foreach (f; score_raised_handlers) f(real_score);
		//foreach (f; handlers) f(real_score);
	}
	
	void RaiseLevel()
	{
		Level++;
		Speed *= .8;
	}
	
	bool DoesCollide(Point pos)
	{
		auto bl = CurrentBlock.GetCurrentShape();
		if (pos.x < 0 || pos.x + CurrentBlock.Width > Size.x ||
			pos.y + CurrentBlock.Height > Size.y) return true; 
		for (uint i=0;i<CurrentBlock.Height;i++) for (uint j=0;j<CurrentBlock.Width;j++)
		{
			if (bl[i*CurrentBlock.Width+j] &&
				m[cast(uint)((i+pos.y)*Size.x+j+pos.x)]) return true;
		}
		return false;
	}
	
	void FixBlock()
	{
		auto bl = CurrentBlock.GetCurrentShape();
		for (uint i=0;i<CurrentBlock.Height;i++) for (uint j=0;j<CurrentBlock.Width;j++)
		{
			if (bl[i*CurrentBlock.Width+j])
			{
				m[cast(uint)((i+CurrentPosition.y)*Size.x+j+CurrentPosition.x)] = bl[i*CurrentBlock.Width+j];
			}
		}
		RemoveCompleteRows();
		CreateNewBlock();
	}
	
	void BuildRandomField(uint level)
	{
		for (uint i=cast(uint)Size.y-level;i<Size.y;i++)
		{
			for (uint j=0;j<Size.x;j++)
			{
				m[i*cast(uint)Size.x+j] = rand() % 4;
			}
		}
	}
	
	void RemoveCompleteRows()
	{
		int Completed = 0;
		Rows:
		for (uint i=0;i<Size.y;i++)
		{
			for (uint j=0;j<Size.x;j++)
			{
				if (!m[i*cast(uint)Size.x+j]) continue Rows;				
			}
			Completed++;
			
			m[cast(uint)Size.x..(i+1)*cast(uint)Size.x] = m[0..i*cast(uint)Size.x].dup;
			m[0..cast(uint)Size.x] = 0;
		}
		
		onLinesComplete(Completed);
	}
	
	void onDraw()
	{
		
	}
	
}

