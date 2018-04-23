module mainmenu;

import glcanvas;
import gameengine.controller;
import block;
import constants;
import std.string;
import derelict.sdl.sdl;

class MainMenu : Model
{
protected:
	static enum MENUITEMS
	{
		NEWGAME,
		TILESET,
		SIZEMUL,
		QUIT
	}
	
	MENUITEMS current_item=MENUITEMS.NEWGAME;
	TILESETS tileset = TILESETS.NORMAL;
	float sizemul = 1;
	
public:
	
	
public:
	enum Event
	{
		NEWGAME,
		QUIT
	};
	
	this()
	{
	}
	
	TILESETS GetTileset()
	{
		return tileset;
	}
	float GetSizeMul()
	{
		return sizemul;
	}
	
	void onKeyDown(SDLKey key)
	{
		switch (key)
		{
		case SDLK_DOWN:
			current_item++;
			if (current_item > MENUITEMS.max) current_item = MENUITEMS.min;
			break;		
		case SDLK_UP:
			current_item--;
			if (current_item < MENUITEMS.min) current_item = MENUITEMS.max;
			break;
		case SDLK_LEFT:
			switch (current_item)
			{
			case MENUITEMS.TILESET:
				tileset--;
				if (tileset < TILESETS.min) tileset = TILESETS.max;
				break;
			case MENUITEMS.SIZEMUL:
				sizemul -= .25;
				if (sizemul < .5) sizemul = 2;
				break;
			default: break;
			}
			break;
		case SDLK_RIGHT:
			switch (current_item)
			{
			case MENUITEMS.TILESET:
				tileset++;
				if (tileset > TILESETS.max) tileset = TILESETS.min;
				break;
			case MENUITEMS.SIZEMUL:
				sizemul += .25;
				if (sizemul > 2) sizemul = .5;
				break;
			default: break;
			}
			break;
		case SDLK_RETURN:
			switch (current_item)
			{
			case MENUITEMS.NEWGAME:
				SendEvent(Event.NEWGAME);
				break;
			case MENUITEMS.QUIT:
				SendEvent(Event.QUIT);
				//SDL_PushEvent(&SDL_Event(SDL_QUIT));
				break;
			default: break;
			}
			break;
		case SDLK_ESCAPE:
			SendEvent(Event.QUIT);
			//SDL_PushEvent(&SDL_Event(SDL_QUIT));
			break;
		default: break;
		}
		
	}
	void onKeyUp(SDLKey key)
	{
		
	}
	void onTick()
	{
		
	}
	
	void onDraw()
	{
		
	}

}

class MainMenuView : View
{
protected:
	MainMenu m;
	alias MainMenu.MENUITEMS MI;
	char[][MI] menu_items;	
public:
	this(MainMenu mm)
	{
		m = mm;
	}
	void Draw()
	{
		menu_items[MI.NEWGAME] = "new game";
		menu_items[MI.TILESET] = format("tileset %s", m.tileset);
		menu_items[MI.SIZEMUL] = format("size %.0fx%.0f", 12*m.sizemul, 16*m.sizemul);
		menu_items[MI.QUIT] = "quit";
		foreach (item, text; menu_items)
		{
			GlCanvas.DrawText(Point(-1, 1-0.5*item), menu_items[item], .05, item == m.current_item ? 2 : 1);
		}
	}
};