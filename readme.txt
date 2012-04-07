## What needs doing.

[x] Display Bots
[x] Roll Dice
[x] Clear Dice
[ ] Mark frames as having finished their move
[ ] Drag white Dice to replace other dice
[ ] Drag yellow dice to spot other frames.
[ ] Add/Edit frames
[ ] Save setups to LocalStorage
[ ] Keep teams together
[ ] Drag bots to reorder


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