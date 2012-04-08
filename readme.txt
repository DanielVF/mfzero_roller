## What needs doing.

[x] Display Bots
[x] Roll Dice
[x] Clear Dice
[x] Mark frames as having finished their move
[ ] Drag white Dice to replace other dice
[ ] Drag yellow dice to spot other frames.
[x] Add/Edit frames
[ ] Save setups to LocalStorage
[x] Keep teams together
[x] User defined frame ordering


## Adding Frames

The especially hardy can add their own frames to the page, by opening up a javascript console on the site, and entering something along the lines of: 

     allFrames.add({
       name: "Scrambler #4",
       team: "green",
       setup: {
         Rh: [2, "Kordavi Ranged Blades"],
         Y: [1, "Laser Designator"],
         B: [1, "Forcefield Module"]
       }
     });