module gameengine.game;

public import gameengine.glcanvas;

class Game
{
protected:
	GlCanvas canvas;
	bool am_running;
	
	float frames_per_second, ticks_per_second;
	
public:
	this(uint xRes, uint yRes)
	{
		canvas = new GlCanvas(xRes, yRes);
		canvas.SetupGl();
	}
	
	void InitLibs()
	{
		
	}
	void ExitLibs()
	{
		
	}

	int Run()
	{
		uint NextTick, NextFrame;
		uint CurrentTick;
		
		uint last_calculation_tick;
		
		CurrentTick = NextTick = NextFrame = last_calculation_tick = SDL_GetTicks();
		
		uint FrameTickInterval = 1000 / 60;
		uint TickInterval = 1000 / 100;
		
		uint frames_this_second;
		uint ticks_this_second;
		
		am_running = true;
		
		mainLoop:
		while(am_running)
		{
			do
			{
				SDL_Delay(1);
				ProcessEvents();
				CurrentTick = SDL_GetTicks();
			} while (NextTick > CurrentTick && NextFrame > CurrentTick);
			
			uint delay_tick = NextTick + 10*TickInterval;
			while (CurrentTick >= NextTick)
			{
				onTick();
				NextTick += TickInterval;
				ticks_this_second++;
				if (NextTick > delay_tick) break;
			}
			
			if (CurrentTick >= NextFrame)
			{
				drawGLFrame();
				frames_this_second++;
				while (CurrentTick >= NextFrame) NextFrame += FrameTickInterval;
			}
			
			/* calculate the actual tick and frame rate */
			if (CurrentTick >= last_calculation_tick + 1000)
			{
				ticks_per_second = cast(float)ticks_this_second * (1000.0/(CurrentTick-last_calculation_tick));
				frames_per_second = cast(float)frames_this_second * (1000.0/(CurrentTick-last_calculation_tick));
				last_calculation_tick = CurrentTick;
				frames_this_second = ticks_this_second = 0;
			}
		}

		return 0;
	}
	
	void onTick()
	{
		
	}
	
	void onEvent(SDL_Event event)
	{
		
	}
	
	void ProcessEvents()
	{
		SDL_Event event;

		while(SDL_PollEvent(&event))
		{
			onEvent(event);
		}
	}
	
	
	void onDraw()
	{
		
	}
	
	void drawGLFrame()
	{
		canvas.Clear();
		
		onDraw();

		canvas.Swap();
	}
	
	
}