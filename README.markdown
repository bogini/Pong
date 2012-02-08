# Pong
## Introduction: Game Concept and Rules
For our minimum deliverable, we created a two player pong game based on existing one-player pong game architectures. Nevertheless, compared to traditional pong games where one player tries to compete to let the other player lose the game, we designed our game to be collaborative, so that the two players can play together to reach a mutual goal of getting a high score. Our team realized that nowadays most of the popular games, such as World of Warcraft, highlight collaboration as an essential game feature. Even in a single player game, collaboration can still exist when one person is watching another person play the game and giving advice about how to win the AI.  Therefore, as our maximum deliverable, we wanted to create competition with the AI for a single player to add diversity and to maintain collaboration between the player and the viewer.  The following are the rules of our pong game: 

* Two Player Mode: 
    1. After either player presses a button, the game starts.
    2. The score increments each time either player hits the ball with the paddle.
    3. When either player misses the ball, the game pauses and a new ball is provided. Three balls are provided in each session.
    4. After three misses from both sides, the game is ended and displays “game over”.
* AI Mode:
    1. After the player presses a button, the game starts.
    2. The score increments each time the AI misses the ball.
    3. When the player or AI misses the ball, the game pauses and a new ball is provide. Three balls are provided for the player.
    4. After three misses on the player’s side, the game is ended and displays “game over”.
    
Being a good player requires good eye-hand coordination, precise control and the ability to predict the path of the ball is actually the key to score high. Moreover, we added variation to the ball speed to add unpredictability as a little challenge that requires a faster reaction of the player. Simple as our game design seems, we still believe that the players can have a lot of fun by the little challenges and the experience of coordination and collaboration.  

## Top-level block diagram of the complete pong game
The following block diagram is created based on tutorials in “FPGA Prototyping by Verilog Examples” because of its simplicity of the game concept and efficiency of implementation with FPGA. 

![Diagram](http://i.imgur.com/fqatc.png "FPGA Prototyping by Verilog Examples")

Inputs: 

* 4 buttons (player 1 ↑, player 1↓, player 2 ↑, player 2↓), 
* AI switch

Outputs: 

* hsync, 
* vsync, 
* red, green, blue (to VGA port)

Modules:

* timer – game timer (determines how long the users can play the game) 
* m100_counter –game counter (2 digit decay counter that counts from 00 to 99, for both scores and lives of the game)
* control _FSM – top-level control (integrates graph and text subsystems and coordinates the overall circuit operation)
* vga_sync – synchronization circuit for VGA 
* pong_graph – game physics backend and graphics display
* pong_text – game text display (utilizes a text ROM which stores all necessary symbols)

## Game logic and graphic generation

Since our implementation uses an object-mapped pixel generation circuit, we need to keep track of objects’ positions in the screen.  For every of the three objects represented (left paddle, right paddle and ball), two variables are used: current position and next position. On the clock rise, the next position data is transferred to the current position variable and the graphics generation module outputs the correct vga signals.

    always @(posedge clk, posedge reset)
          if (reset)
             begin
                barr_y_reg <= 0;
                barl_y_reg <= 0;
                ball_x_reg <= 0;
                ball_y_reg <= 0;
                x_delta_reg <= 10'h004;
                y_delta_reg <= 10'h004;
             end   
          else
             begin
                barr_y_reg <= barr_y_next;
                barl_y_reg <= barl_y_next;
                ball_x_reg <= ball_x_next;
                ball_y_reg <= ball_y_next;
                x_delta_reg <= x_delta_next;
                y_delta_reg <= y_delta_next;
             end   

By building a frame-by-frame logic, we have easy access to the next position of the objects. This allows us to implement artificial intelligence into the game in a straightforward way.

### Playing against the computer
On modern versions of Pong, artificial intelligence is implemented in a very simple way: the computer controller paddle follows the ball in every step. The center of the paddle is always aligned with the center of ball. After implementing this version, we realized that the gameplay became unnatural and difficult. By observation of human gameplay we realized that the way a human plays is very particular. It seems that players follow the ball with their eyes at every moment but only start reacting – by adjusting their paddle position – once the ball has hit the opponent’s player and is roughly at one third of the way. We decided that implementing the logic behind the AI following this rule, which resulted in such a natural gameplay that it is sometimes hard to discern the human from the computer by looking at the screen.

AI implementation:

    always @*
       begin
          if (ai_switch)
             begin
                if (ball_x_l < 2*(MAX_X / 3) && refr_tick)
                   begin
                      ball_center = ball_y_t + ((ball_y_b - ball_y_t) / 2);
                      paddlel_center = barl_y_t + ((barl_y_b - barl_y_t) / 2);
                      if (ball_center < paddlel_center)
                         begin
                            barl_y_next = barl_y_reg - 3; // move up
                            if (barl_y_next <= 5)
                               barl_y_next = 5;
                         end
                      else if (ball_center > paddlel_center)
                         begin
                            barl_y_next = barl_y_reg + 3; // move down
                            if (barl_y_next + BARL_Y_SIZE >= MAX_Y)
                               barl_y_next = MAX_Y - BARL_Y_SIZE;
                         end
                      else
                         barl_y_next = barl_y_reg; // no move
                   end
                else
                   barl_y_next = barl_y_reg; // no move
             end
          else
             begin
                barl_y_next = barl_y_reg; // no move
                if (gra_still) // initial position of paddle
                   barl_y_next = (MAX_Y-BARL_Y_SIZE)/2;
                else if (refr_tick)
                   if (btn2[1] && (barl_y_b < (MAX_Y-1-BARL_V)))
                      barl_y_next = barl_y_reg + BARL_V; // move down
                   else if (btn2[0] && (barl_y_t > BARL_V)) 
                      barl_y_next = barl_y_reg - BARL_V; // move up
             end
       end

To determine in which mode we are currently playing, we first check the value of ai_switch, which is mapped to one of the switches in the FPGA. When in AI mode, the paddle only moves once the ball has travelled one third of the way and the clock is raised. It is then determined where the ball currently is and whether the paddle needs to move up or down. In order to avoid the paddle going off the screen, we check if the top of the paddle is higher than the top of the screen and the bottom of the paddle lower than the screen bounds. If it is, we place the paddle in the topmost or bottommost position, depending on which of the boundaries was surpassed.

As it can be seen in the implementation, the computer controlled paddle moves with a speed of 3 pixels per clock tick. We chose this speed because it is lower than the player’s (4 pixels per clock tick). This allows the player to win the AI in some situations making the game challenging and enjoyable.

## Animation

In order to create the animated display result, registers are used to store the boundaries of the ball. The values of these registers are updated every time the screen of the VGA monitor refreshes. We need to determine how to change these values to make the game flow smooth and natural.
We start with the ball moving at a constant speed. The direction of the ball changes when it hits the paddles, the bottom or top of the screen. We decompose the velocity into an x-component and a y-component, whose value can either be 2 or -2. The bounce motion of the ball is simulated by- when the ball hits the paddles, the x-component of the velocity flips its sign and the y-component stays the same; when the ball hits the top or the bottom of the screen, the y-component of the velocity flips its sign and the x-component does not change.
This method works well except there is one drawback: because the ball always moves at 45 degrees angle, there is a repetitive pattern of where it hits the paddle every time it bounces. As it comes to be obvious to the players, the game becomes boring very fast. To make our game more unpredictable, therefore, more interesting, we implement a new method for the ball to bounce off the paddles. We are going to use the right paddle as an example. The paddle is divided into five regions as shown in Figure.1.

![Figure 1](http://i.imgur.com/uSsgH.png "Figure 1. Figure x-component of velocity changes depending on the impact regions of the paddle")

 When the ball hits the paddle, the y-component stays the same, but the x-component not only change its sign, but also change its magnitude depending on the impact region of the. For example, regardless of the velocity of the ball when it hits the paddle, as long as it hits at the outmost parts of the paddle, the x-component of the bounce speed becomes -4.