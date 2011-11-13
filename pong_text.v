module pong_text
    (
     input wire clk,
     input wire [1:0] ball,
     input wire [9:0] pix_x, pix_y,
     output wire [3:0] text_on,
     output reg [2:0] text_rgb
    );
     
    // Signal declaration
    wire [10:0] rom_addr;
    reg [6:0] char_addr, char_adrr_s, char_addr_1, char_addr_r, char_addr_o;
    reg [3:0] row_addr;
    wire [3:0] row_addr_s, row_addr_1_ row_addr_r, row_addr_o;
    wire [7:0] font_word;
    wire font_bit, score_on, logo_on, rule_on, over_on;
    wire [7:0] rule_rom_addr;
    
    // instantiate font ROM
    font_rom font_unit(.clk(clk), .addr(rom_addr), .data(font_word));
    
    assign score_on = (pix_y[9:5]==0) && (pix_x[9:4]<16);
    assign row_addr_s = pix_x[4:1];
    assign bit_addr_s = pix_x[3:1];
    always @*
        case (pix_x[7:4])
            4'h0: char_addr_s = 7'h53; // S
            4'h1: char_addr_s = 7'h63; // c
            4'h2: char_addr_s = 7'h6f; // o
            4'h3: char_addr_s = 7'h72; // r
            4'h4: char_addr_s = 7'h65; // e
            4'h5: char_addr_s = 7'h3a; // :
            4'h6: char_addr_s = {3'b011, dig1}; // 10
            4'h7: char_addr_s = {3'b011, dig0}; // 1
            4'h8: char_addr_s = 7'h00; // 
            4'h9: char_addr_s = 7'h00; // 
            4'ha: char_addr_s = 7'h42; // B
            4'hb: char_addr_s = 7'h61; // a
            4'hc: char_addr_s = 7'h6c; // l
            4'hd: char_addr_s = 7'h6c; // l
            4'he: char_addr_s = 7'h3a; // :
            4'hf: char_addr_s = {3'b01100, ball};
        endcase
    
    // Logo
    assign logo_on = (pix_y[9:7]==2) && (3<=pix_x[9:6]) && (pix_x[9:6]<=6);
    assign row_addr_1 = pix_y[6:3];
    assign bit_addr_1 = pix_x[5:3];
    always @*
        case (pix_x[8:6])
            3'o3: char_addr_1 = 7'h50; // P
            3'o4: char_addr_1 = 7'h4f; // O
            3'o5: char_addr_1 = 7'h4e; // N
            default: char_addr_1 = 7'h47; // G
        endcase
        
    // Rule region
    assign rule_on = (pix_x[9:7]==2) && (pix_y[9:6]==2);
    assign row_addr_r = pix_y[3:0];
    assign bit_addr_r = pix_x[2:0];
    assign rule_rom_addr = {pix_y[5:4], pix_x[6:3]};
    always @*
        case (rule_rom_addr)
        // row 1
        6'h00: char_addr_r = 7'h52; // R
        6'h01: char_addr_r = 7'h55; // U
        6'h02: char_addr_r = 7'h4c; // L
        6'h03: char_addr_r = 7'h45; // E
        6'h04: char_addr_r = 7'h3a; // :
        6'h05: char_addr_r = 7'h52; // 
        6'h06: char_addr_r = 7'h52; // 
        6'h07: char_addr_r = 7'h52; // 
        6'h08: char_addr_r = 7'h52; // 
        6'h09: char_addr_r = 7'h52; // 
        6'h0a: char_addr_r = 7'h52; // 
        6'h0b: char_addr_r = 7'h52; // 
        6'h0c: char_addr_r = 7'h52; // 
        6'h0d: char_addr_r = 7'h52; // 
        6'h0e: char_addr_r = 7'h52; // 
        6'h0f: char_addr_r = 7'h52; //   
        // row 2
        6'h10: char_addr_r = 7'h52; // U
        6'h01: char_addr_r = 7'h55; // s
        6'h02: char_addr_r = 7'h4c; // e
        6'h03: char_addr_r = 7'h45; // 
        6'h04: char_addr_r = 7'h3a; // t
        6'h05: char_addr_r = 7'h52; // w
        6'h06: char_addr_r = 7'h52; // o
        6'h07: char_addr_r = 7'h52; // 
        6'h08: char_addr_r = 7'h52; // b
        6'h09: char_addr_r = 7'h52; // u
        6'h0a: char_addr_r = 7'h52; // t
        6'h0b: char_addr_r = 7'h52; // t
        6'h0c: char_addr_r = 7'h52; // o
        6'h0d: char_addr_r = 7'h52; // n
        6'h0e: char_addr_r = 7'h52; // s
        6'h0f: char_addr_r = 7'h52; //
    