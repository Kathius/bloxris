module bloxris.main;

import std.string;
import std.stdio;
import std.thread;
import std.file;
import std.conv;
import derelict.util.exception;

import gameengine.controller;
import gameengine.game;
import constants;
import playfield;
import mainmenu;

//horizontal and vertical screen resolution
const int xResolution = 800;
const int yResolution = 600;

//number of bits per pixel used for display. 24 => true color
const int bitsPerPixel = 24;

bool myMissingProcCallback(char[] libName, char[] procName)
{
	// there are 8 functions in SDL's CPU interface - test for them all.
	// If the procName matches any one of them, return true to ignore the missing
	// function.
	if( procName.cmp("Mix_SetReverb") == 0)
			return true;		// ignore the error and throw no exception

	// a function other than one of those above failed to load - return false
	// to indicate that an exception should be thrown.
	return false;
}


void init()
{
	// initialize the SDL Derelict module
	Derelict_SetMissingProcCallback(&myMissingProcCallback);
	
	DerelictSDL.load();
	DerelictGL.load();
	DerelictGLU.load();

	// initialize SDL's VIDEO module
	SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER);
	
	// enable double-buffering
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	
	// create our OpenGL window
	SDL_SetVideoMode(xResolution, yResolution, bitsPerPixel, SDL_OPENGL);
	SDL_WM_SetCaption(toStringz("My SDL Window"), null);
	
}

//be nice and release all resources
void cleanup()
{
	// tell SDL to quit
	SDL_Quit();

	// release SDL's shared lib
	DerelictGLU.unload();
	DerelictGL.unload();
	DerelictSDL.unload();
}


void main()
{
	init();
	scope(exit) cleanup(); // when we exit, perform cleanup
	
	auto game = new Bloxris();
	game.Start();
}

class Bloxris : Game
{
protected:
	auto BlockSize = .2;
	auto BlocksH = 12;
	auto BlocksV = 16;
	
	Playfield field;
	PlayfieldView field_view;
	MainMenu menu;
	MainMenuView menu_view;
	
	uint[] HiScore;
		
	Model current_screen;
	View current_view;
	
protected:

	this()
	{
		super(xResolution, yResolution);
	}
	
	void Init()
	{
		menu = new MainMenu();
		menu_view = new MainMenuView(menu);
		menu.RegisterEventHandler(MainMenu.Event.NEWGAME, &NewGame);
		menu.RegisterEventHandler(MainMenu.Event.QUIT, &onQuit);
		current_screen = menu;
		current_view = menu_view;
	}
	
	void LoadHiscore()
	{
		if (!std.file.exists("hiscore")) return;
		auto content = (cast(char[])std.file.read("hiscore")).split("\n");
		foreach (line; content)
		{
			HiScore ~= std.conv.toInt(line);
		}
		HiScore.sort.reverse;
	}
	void WriteHiscore()
	{
		char[][] txtscores;
		foreach (score; HiScore) txtscores ~= std.string.toString(score);
		std.file.write("hiscore", txtscores.join("\n"));
	}
	void AddHiscore()
	{
		HiScore ~= field.GetScore;
		HiScore.sort.reverse;
		if (HiScore.length > 10) HiScore.length = 10;
	}
	
	void Start()
	{
		Init();
		LoadHiscore();
		Run();
	}
	void NewGame()
	{
		field = new Playfield(Point(12, 16)*menu.GetSizeMul(), menu.GetTileset());
		field_view = new PlayfieldView(field, Point(-2.6, -1.6), .2/menu.GetSizeMul());
		current_screen = field;
		current_view = field_view;
	}
	void onQuit()
	{
		SDL_PushEvent(&SDL_Event(SDL_QUIT));
	}
	void LoseGame()
	{
		AddHiscore();
		WriteHiscore();
		current_screen = menu;
		current_view = menu_view;
	}
	
	void onEvent(SDL_Event event)
	{
		switch(event.type)
		{
		case SDL_QUIT:
			am_running = false;
			break;
		case SDL_KEYDOWN:
			current_screen.onKeyDown(event.key.keysym.sym);
			break;
		case SDL_KEYUP:
			current_screen.onKeyUp(event.key.keysym.sym);
			break;
		default:
			break;
		}
		
	}

	void onTick()
	{
		current_screen.onTick();
		current_view.onTick();
	}
	
	void onDraw()
	{
		current_view.Draw();
		
		GlCanvas.DrawText(Point(1.9, 1.95), format("fps: %2.2f", frames_per_second), .02);
		GlCanvas.DrawText(Point(1.9, 1.75), format("tps: %2.2f", ticks_per_second), .02);

		foreach (iScore, score; HiScore)
		{
			GlCanvas.DrawText(Point(1.5, 0.5-iScore*.2), format("%d. %d", iScore+1, score), .03);
		}
	}
};

