# Raspberry Pi Snake
Classic snake game for NES on a Raspberry Pi Model B barebones no OS. Control the game using an SNES controller on GPIO pins 9-11 (Latch, Data, Clock). Use the D-pad to move left, right, up, and down and navigate menus. Start pauses the game and A selects a menu option. Collect 20 apples to win the game, crashing into a wall or the snakes body resets the snake and takes a life. When your life count hits zero you lose and the game is over. After eating 20 apples a door will appear that must be entered to win. Drill power-ups will spawn randomly throughout the game, picking them up allows you to destroy a wall block without dying.

# Compilation & Running
Connect remote debugging device and launch GDB server. Make sure HDMI cable is connected before powering on Raspberry Pi.

$ target remote localhost:2331
$ make
$ load
$ j _start