
### What is my design in UI? ###

I'll describe about my design about Maze UI(just the maze view part).

Maze view consists of two view:

1, UIImageView named "Border" in storyboard, it's the "Border.png", the background imageview of maze.
2, UIView named "Maze View" in storyboard

1&2 they have same frame size, and tiles(the maze) is draw in 2, and start room is in (0,0), as we don't what the exact size of 2, so everytime when a new room is fetched(a new tile is added in 2), we have to adjust 2 to make sure maze is overlapping on 1, then 1 and 2's location might be like below, but actually user will see a maze on Bordar background. 


-----------                   -----------
|         |                   |---|||-__|
|         |                   |||_--|--||
|    1    |                   ||||||__|||
|         |                   |____|||__|
|      ********** ----------> |--|||---_|******   
|      *  |     *             |___||----|     *
-------*---     *             -------*---     *
       *    2   *                    *        *
       *        *                    *        *
       *        *                    *        *
       **********                    **********


### How do I get set up? ###

* cocoapods setup




