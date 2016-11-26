# Springback

The Springback control behaves like a spring-loaded joystick which returns to its central position. However, with the Springback control, the central position or *touch down origin* (TDO) can be anywhere inside a window. A finger drag action causes the control to move away from that TDO. Whilst a touch up action causes the control to return to the TDO at a specified/configurable rate.

The demonstration shows how the Springback control can be used to
- pan quickly (or slowly) over a very large area
- reach a specific destination very accurately without overshooting
- provide an alternative maneuver mechanism to excessive swiping

# Technical

The demo uses a storyboard consisting of two view controllers
- ViewController.m - an ObjC view controller which references an ObjC Springback control (class SpringbackControl)
- ViewControllerSw.m - an ObjC view controller which references a Swift Springback control (class SpringbackControlSw) ... *this one is for all you Swift pioneers!*

The two pieces of code are almost identifical except for the type of SpringbackControl instance.

To embed the control into your own projects, you need only the files under the *Control* group/folder, and the control can be created programmatically or accessed like any other standard control in Interface Builder.

# Objc

Tracing is turned on/off using a compiler preprocessing setting of SBCLOG_LEVEL=1, 2 or 3  
(1 is quiet, 3 is noisy)

# Swift

This code is version 2.2. I've not migrated to 3.0 yet, so apologies for any incompatibility issues.  
Tracing is turned on/off using a custom flag -DSBCLOG_LEVEL1, -DSBCLOG_LEVEL2, or -DSBCLOG_LEVEL3  
(1 is quiet, 3 is noisy)

*(Oh, and please don't complain about the direction of the "Reverse Pan" setting. That's part of the demo, not the actual control)*

Have fun  
Sheun

# Contact

Sheun Olatunbosun
- https://github.com/sheuno
- sheuno@gmail.com

# License

Apache License, Version 2.0,  
Copyright (c) 2016 Sheun Olatunbosun
