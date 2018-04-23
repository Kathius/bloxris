module gameengine.model;

import derelict.sdl.sdl;

abstract class Model
{
protected:
	EventHandler[][uint] event_handlers;
public:
	alias void delegate() EventHandler;
	
	void onKeyDown(SDLKey key);
	void onKeyUp(SDLKey key);
	
	void RegisterEventHandler(uint event, EventHandler handler)
	{
		event_handlers[event] ~= handler;
	}
	void SendEvent(uint event)
	{
		if (!(event in event_handlers)) return;
		foreach (f; event_handlers[event])
		{
			f();
		}
	}
	
	void onTick();
	void onDraw();
}