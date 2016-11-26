# Springback

The Springback control behaves like a spring-loaded joystick which returns to its center position. However, with the Springback control, the centre (or origin) can be anywhere in a window since it's the initial touch down point. The control also has a return delay which determines how quickly the joystick returns to its starting point.

The demonstration shows how the Springback control can be used to pan quickly (or slowly) over a very large area and how accurately it can reach a precise destination. All this can be achieved without excessing swiping.

# Technical

Demo uses a storyboard consisting of two view controllers

ViewController.m - ObjC controller with embedded ObjC SpringbackControl (SpringbackControl)
ViewControllerSw.m - ObjC controller with embedded Swift SpringbackControl (SpringbackControlSw)

The two pieces of code are almost identifical excetpt for the embedded SpringbackControl.

To embed the control into your own projects, you only need the files under the Control group/folder, and the control can be configured like any other standard control in Interface Builder.

# Objc

Tracing is turned on/off using a custom flag SBCLOG_LEVEL=1, 2 or 3
(1 is quite, 3 is noisy)

# Swift

This is version 2.2. Not migrated to 3.0 yet. Sorry for any incompatibility issues.
Tracing is turned on/off using a custom flag -DSBCLOG_LEVEL1, -DSBCLOG_LEVEL2, or -DSBCLOG_LEVEL3
(1 is quite, 3 is noisy)


(Oh, and please don't complain about the direction of the "Reverse Pan" setting. That's part of the demo, not the actual control)

Have fun
Sheun

# Contact

Sheun Olatunbosun
- https://github.com/sheuno

# License

Apache License, Version 2.0, Copyright (c) 2016 Sheun Olatunbosun