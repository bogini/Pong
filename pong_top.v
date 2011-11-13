module pong_top
    (
     input wire clk, reset,
     input wire [1:0] btn,
     output wire hsync, vsync,
     output wire [2:0] rgb
     );
     
     // Symbolic state declaration
     localparam   [1:0]
        newgame = 2'b00,
        play    = 2'b01,
        newball = 2'b10,
        over    = 2'b11,
        
    // Signal declaration
    reg [1:0] state_reg, state_next;
    wire [9:0] pixel_x, pixel_y;
    wire video_on, pixel_tick, graph_on, hit, miss;
    wire [3:0] text_on;
    wire [2:0] graph_rgb, text_rgb;
    reg [2:0] rgb_reg, rgb_next;
    wire [3:0] dig0, dig1;
    reg gra_still, d_inc, d_clr, timer_start;
    wire timer_tick, timer_up;
    reg [1:0] ball_reg, ball_next;
    
    // Instantiation
    // Instantiate video synchronization unit
    vga_sync vsync_unit(.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync), .video_on(video_on), .p_tick(pixel_tick), .pixel_x(pixel_x), .pixel_y(pixel_y));
    // Instantiate text module
    pong_text text_unit(.clk(clk), .pix_x(pixel_x), .pix_y(pixel_y), .dig0(dig0), .dig1(dig1), .ball(ball_reg), .text_on(text_on), .text_rgb(text_rgb));
    // Instantiate graph module
    pong_graph graph_unit(.clk(clk), .reset(reset), .btn(btn), .pix_x(pixel_x), .pix_y(pixel_y), .gra_still(gra_still), .hit(hit), .miss(miss), .graph_on(graph_on), .graph_rgb(graph_rgb));
    // Instantiate 2 sec timer
    // 60 Hz tick
    assign timer_tick = (pixel_x == 0) && (pixel_y == 0);
    timer timer_unit(.clk(clk), .reset(reset), .timer_tick(timer_tick), .timer_start(timer_start), .timer_up(timer_up));
    // Instantiate 2-digit decade counter
    m100_counter counter_unit(.clk(clk), .reset(reset), .d_inc(d_inc), .d_clr(d_clr), .dig0(dig0), .dig1(dig1));
    
    // FSMD
    // FSMD state & data registers
    always @(posedfe clk, posedge reset)
        if (reset)
            begin
                state_reg <= newgame;
                ball_reg <= 0;
                rgb_reg <= 0;
            end
        else
            begin
                state_reg <= state_next;
                ball_reg <= ball_next;
                if (pixel_tick)
                    rgb_reg <= rgb_next;
            end
    // FSMD next-state logic
    always @*
    begin
        gra_still = 1'b1;
        timer_star = 1'b0;
        d_inc = 1'b0;
        d_clr = 1'b0;
        state_next = state_reg;
        ball_next = ball_reg;
        case (state_reg)
            newgame:
                begin
                    ball_next = 2'b11; // 3 balls
                    d_clr = 1'b1;
                    if (btn != 2'b00) // Button pressed
                        begin
                            state_next = play;
                            ball_next = ball_reg - 1;
                        end
                end
            play:
                begin
                    gra_still = 1'b0; // Animated screen
                    if (hit)
                        d_inc = 1'b1; // Increment score
                    else if (miss)
                        begin
                            if (ball_reg == 0)
                                state_next = pver;
                            else
                                state_next = newball;
                            timer_start = 1'b1; // 2 sec timer
                            ball_next = ball_reg -1;
                        end
                end
            newball:
                // Wait for 2 sec and until button pressed
                if (timer_up && (btn != 2'b00))
                    state_next = play;
            over:
                // Wait for 2 sec to display game over
                if (timer_up)
                    state_next = newgame;
        endcase
    end
    
    // RGB mutiplexing circuit
    always @*
        if (~video_on)
            rgb_next = "000"; // Blank th edge/retrace
        else
            // Display score, rule or game over
            if (text_on[3] || ((state_reg == newgame) && text_on[1]) || (state_reg == over) && text_on[0]))
                rgb_next = text_rgb;
            else if (graph_on) // Display graph
                rgb_next = graph_rgb;
            else if (text_on[2]) // Display logo
                rgb_next = text_rgb;
            else
                rgb_next = 3'b110; // Yellow background
    // output
    assign rgb = rgb_reg;
endmodule