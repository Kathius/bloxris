module gameengine.controller;

public import gameengine.model, gameengine.view;

import derelict.sdl.sdl;

abstract class Controller
{
public:
	void onKeyDown(SDLKey key);
	void onKeyUp(SDLKey key);

}