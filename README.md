# Interactive Water Shader for Godot 4.3

https://github.com/user-attachments/assets/aae2f72f-3ba4-432e-94e8-87851e1d61f2

## Why
I've had various implementations of this kind of thing lying around for who knows how long and figured I'd try it in Godot.

From memory, the original source was someone's personal tech-blog implementation in C from the late 90's which explained the maths better than I could,
but is unfortunately lost to time (I used to have an archive link hanging around in my bookmarks, but those have also been lost to the Firefox account-sync aether).

If anyone does happen to find the link please drop an issue/PR and I'll properly credit it here.

## How
Basic idea is a [-1,1] heightmap containing both current and previous moments (in RED and GREEN channels, respectively) 
which is then ping-ponged into a new buffer, in the process spatially dispersing the current height and rotating the moments.

The produced heightmap is then used both as vertex displacement, as well as for surface-normal approximation.

This leads to some pretty natural results, but also has some pretty severe drawbacks:
- Simulation is framerate and resolution dependent - ideally you would just simulate manually at eg. 30Hz,
  but I'm abusing Subviewports to get this working which are tied to the main render loop.
- Configuration is limited and painful - I've tuned the defaults to work but it breaks easily.
- I've done a bit of generic parameterisation, but most of this was originally hardcoded to the test scene so may not 'just work' out of context.
- Aforementioned Subviewport abuse is the only simple way I found to get ping-pong buffering working in Godot -
  a ViewportTexture cannot reference its own Viewport, so we need a nested Subviewport to get working double-buffering
  (yes, the viewports reference each other):

![subviewports](https://github.com/user-attachments/assets/2b3716ee-fc18-4e32-ba50-588b940d0b86 "forgive me father for i have sinned")

Water-surface shader itself is otherwise pretty standard:
- Simple surface waves from normal-map composition
- Screen-space refraction
- Linear depth scattering
- Poor-man's depth blur using screen-texture mipmap offsets
