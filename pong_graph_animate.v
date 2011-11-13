module pong graph animate
    (
     input wire clk, reset,
     input wire video_on,
     input wire [1:0] btn,
     input wire [9:0] pix_x, pix_y,
     output reg [2:0]
     );
     
     //
     