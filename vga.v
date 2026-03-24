module vga (
    input  wire       clk_50mhz,   
    input  wire       reset,   
    input  wire [4:0] ring_counter,
    
    // ENTRADAS DE DADOS (Binário Puro)
    input  wire [3:0]   pc_bin,
    input  wire [3:0]   mar_bin,
    input  wire [7:0]   ir_bin,
    input  wire [7:0]   acc_bin,
    input  wire [7:0]   alu_bin,
    input  wire [7:0]   breg_bin,
    input  wire [7:0]   opr_bin,
    input  wire [127:0] ram_bin, // 16 endereços * 8 bits
    
    // Sinais de controle
    input wire sig_pc_out, sig_pc_inc, sig_jmp, sig_acc_in, sig_acc_out, 
               sig_mar_in, sig_ram_in, sig_ram_out, sig_alu_out, sig_alu0, 
               sig_alu1, sig_add_sub, sig_xor_not, sig_br_in, sig_ir_in, sig_ir_out, 
               sig_opr_in, sig_hlt,
    
    // Saídas VGA
    output reg       hsync,        
    output reg       vsync,        
    output reg [3:0] red,           
    output reg [3:0] green,         
    output reg [3:0] blue           
);
    
    // ==================================
    // Divisor de clock 50MHz -> 25MHz
    // ==================================
    reg clk_25mhz_reg = 0;
    always @(posedge clk_50mhz or posedge reset) begin
        if (reset)
            clk_25mhz_reg <= 0;
        else
            clk_25mhz_reg <= ~clk_25mhz_reg;
    end
    wire clk_25mhz = clk_25mhz_reg;

    // ================================
    // Parâmetros do VGA 640x480 @60Hz
    // ================================
    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_PULSE   = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = H_DISPLAY + H_FRONT + H_PULSE + H_BACK;

    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_PULSE   = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = V_DISPLAY + V_FRONT + V_PULSE + V_BACK;

    // ===================================
    // Contadores horizontal e vertical
    // ===================================
    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;
    
  
    always @(posedge clk_25mhz or posedge reset) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end
    
	 wire [9:0] pixel_x = h_count;
    wire [9:0] pixel_y = v_count;

    // ===========================================
    // Sinais HSYNC e VSYNC 
    // ===========================================

    wire hsync_comb = ~((pixel_x >= H_DISPLAY + H_FRONT) &&
                        (pixel_x <  H_DISPLAY + H_FRONT + H_PULSE));
    wire vsync_comb = ~((pixel_y >= V_DISPLAY + V_FRONT) &&
                        (pixel_y <  V_DISPLAY + V_FRONT + V_PULSE));

    // =======================
    // Região Visível
    // =======================
    wire video_on = (pixel_x < H_DISPLAY) && (pixel_y < V_DISPLAY);

    // ========================================
    // RETANGULOS QUE REPRESENTAM OS MODULOS
    // ========================================
    localparam PC_X0   = 53,  PC_Y0   = 24,  PC_X1   = 242, PC_Y1   = 96;
    localparam MAR_X0  = 53,  MAR_Y0  = 111, MAR_X1  = 242, MAR_Y1  = 183;
    localparam RAM_X0  = 53,  RAM_Y0  = 197, RAM_X1  = 242, RAM_Y1  = 380;
    localparam IR_X0   = 53,  IR_Y0   = 393, IR_X1   = 242, IR_Y1   = 464;
    localparam BUS_X0  = 306, BUS_Y0  = 24,  BUS_X1  = 335, BUS_Y1  = 435;
    localparam ACC_X0  = 400, ACC_Y0  = 24,  ACC_X1  = 589, ACC_Y1  = 96;
    localparam ALU_X0  = 400, ALU_Y0  = 111, ALU_X1  = 589, ALU_Y1  = 183;
    localparam B_X0    = 400, B_Y0    = 197, B_X1    = 589, B_Y1    = 269;
    localparam OUT_X0  = 400, OUT_Y0  = 284, OUT_X1  = 589, OUT_Y1  = 355;
    localparam CTRL_X0 = 400, CTRL_Y0 = 371, CTRL_X1 = 592, CTRL_Y1 = 469;
    
    // Detecção se o pixel atual está na borda de algum módulo
	 
	 wire b_pc = ((pixel_x == PC_X0 || pixel_x == PC_X1) && (pixel_y >= PC_Y0 && pixel_y <= PC_Y1)) || 
                ((pixel_y == PC_Y0 || pixel_y == PC_Y1) && (pixel_x >= PC_X0 && pixel_x <= PC_X1));
					 			 
    wire b_mar = ((pixel_x == MAR_X0 || pixel_x == MAR_X1) && (pixel_y >= MAR_Y0 && pixel_y <= MAR_Y1)) || 
                 ((pixel_y == MAR_Y0 || pixel_y == MAR_Y1) && (pixel_x >= MAR_X0 && pixel_x <= MAR_X1));
    
    wire b_ram = ((pixel_x == RAM_X0 || pixel_x == RAM_X1) && (pixel_y >= RAM_Y0 && pixel_y <= RAM_Y1)) || 
                 ((pixel_y == RAM_Y0 || pixel_y == RAM_Y1) && (pixel_x >= RAM_X0 && pixel_x <= RAM_X1));
    
	 wire b_ir  = ((pixel_x == IR_X0 || pixel_x == IR_X1) && (pixel_y >= IR_Y0 && pixel_y <= IR_Y1)) || 
                 ((pixel_y == IR_Y0 || pixel_y == IR_Y1) && (pixel_x >= IR_X0 && pixel_x <= IR_X1));
					  
    wire b_bus = ((pixel_x == BUS_X0 || pixel_x == BUS_X1) && (pixel_y >= BUS_Y0 && pixel_y <= BUS_Y1)) || 
                 ((pixel_y == BUS_Y0 || pixel_y == BUS_Y1) && (pixel_x >= BUS_X0 && pixel_x <= BUS_X1));
					  
    wire b_acc = ((pixel_x == ACC_X0 || pixel_x == ACC_X1) && (pixel_y >= ACC_Y0 && pixel_y <= ACC_Y1)) || 
                 ((pixel_y == ACC_Y0 || pixel_y == ACC_Y1) && (pixel_x >= ACC_X0 && pixel_x <= ACC_X1));
					  
    wire b_alu = ((pixel_x == ALU_X0 || pixel_x == ALU_X1) && (pixel_y >= ALU_Y0 && pixel_y <= ALU_Y1)) || 
                 ((pixel_y == ALU_Y0 || pixel_y == ALU_Y1) && (pixel_x >= ALU_X0 && pixel_x <= ALU_X1));
					  
	 wire b_breg = ((pixel_x == B_X0 || pixel_x == B_X1) && (pixel_y >= B_Y0 && pixel_y <= B_Y1)) || 
                  ((pixel_y == B_Y0 || pixel_y == B_Y1) && (pixel_x >= B_X0 && pixel_x <= B_X1));
    
    wire b_out = ((pixel_x == OUT_X0 || pixel_x == OUT_X1) && (pixel_y >= OUT_Y0 && pixel_y <= OUT_Y1)) || 
                 ((pixel_y == OUT_Y0 || pixel_y == OUT_Y1) && (pixel_x >= OUT_X0 && pixel_x <= OUT_X1));
					  
    wire b_ctrl = ((pixel_x == CTRL_X0 || pixel_x == CTRL_X1) && (pixel_y >= CTRL_Y0 && pixel_y <= CTRL_Y1)) || 
                  ((pixel_y == CTRL_Y0 || pixel_y == CTRL_Y1) && (pixel_x >= CTRL_X0 && pixel_x <= CTRL_X1));
            
    // Sinais para detectar atividade dos Módulos (Para colorir a borda)
    wire active_pc   = sig_pc_out | sig_pc_inc | sig_jmp;
    wire active_mar  = sig_mar_in;
    wire active_ram  = sig_ram_in | sig_ram_out;
    wire active_ir   = sig_ir_in  | sig_ir_out;
    wire active_acc  = sig_acc_in | sig_acc_out;
    wire active_alu  = sig_alu_out | sig_alu0 | sig_alu1 | sig_add_sub | sig_xor_not;
    wire active_b    = sig_br_in;
    wire active_out  = sig_opr_in;
    wire active_bus  = sig_pc_out | sig_acc_out | sig_alu_out | sig_ram_out | sig_ir_out; 
    
    // Agrupa todas as bordas para decisão final
    wire any_border = b_pc | b_mar | b_ram | b_ir | b_bus | b_acc | b_alu | b_breg | b_out | b_ctrl;
	 
	 reg [3:0] red_border, green_border, blue_border;
	 wire border_is_active;
	 
	 assign border_is_active = 
	 (b_pc   && active_pc)  | (b_mar  && active_mar) | 
     (b_ram  && active_ram) | (b_ir   && active_ir)  | 
     (b_acc  && active_acc) | (b_alu  && active_alu) | 
     (b_breg && active_b)   | (b_out  && active_out) | 
     (b_bus  && active_bus);

	 always @(*) begin
		{red_border, green_border, blue_border} = border_is_active ? {4'hF, 4'h0, 4'h0}
																   : {4'hF, 4'hF, 4'hF};
	 end
		 

    //===================================================
    // SETAS QUE LIGAM OS MODULOS AO BARRAMENTO
    //===================================================
    
     wire ar_pc_bus, ar_bus_pc, ar_bus_mar, ar_ram_bus, ar_bus_ram, ar_ir_bus, ar_bus_ir, ar_ir_control,
     ar_acc_bus, ar_bus_acc, ar_alu_bus, ar_bus_breg, ar_bus_outreg, ar_mar_ram, ar_breg_alu, ar_acc_alu;
    
    
     //PC -> BUS
     arrows ar_pc_bus_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(242), .y0(50), .x1(305), .y1(50), 
                                         .v_len(5), .dir(0), .pixel(ar_pc_bus) );
    //BUS -> PC                             
     arrows ar_bus_pc_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(242), .y0(70), .x1(305), .y1(70), 
                                         .v_len(5), .dir(1), .pixel(ar_bus_pc) );
    //BUS -> MAR                                
     arrows ar_bus_mar_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(242), .y0(147), .x1(305), .y1(147), 
                                         .v_len(5), .dir(1), .pixel(ar_bus_mar) );
    //RAM -> BUS                                
     arrows ar_ram_bus_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(242), .y0(278), .x1(305), .y1(278), 
                                         .v_len(5), .dir(0), .pixel(ar_ram_bus) );
     //BUS -> RAM
     arrows ar_bus_ram_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(242), .y0(299), .x1(305), .y1(299), 
                                         .v_len(5), .dir(1), .pixel(ar_bus_ram) );
    //IR -> BUS                                    
     arrows ar_ir_bus_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(242), .y0(418), .x1(305), .y1(418), 
                                         .v_len(5), .dir(0), .pixel(ar_ir_bus) );
    //BUS -> IR
     arrows ar_bus_ir_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(242), .y0(433), .x1(305), .y1(433), 
                                         .v_len(5), .dir(1), .pixel(ar_bus_ir) );
    //IR -> CONTROL
     arrows ar_ir_control_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(242), .y0(454), .x1(399), .y1(454), 
                                         .v_len(5), .dir(0), .pixel(ar_ir_control) );
     //ACC -> BUS    
     arrows ar_acc_bus_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(335), .y0(50), .x1(399), .y1(50), 
                                         .v_len(5), .dir(1), .pixel(ar_acc_bus) );
     //BUS -> ACC                                     
     arrows ar_bus_acc_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(335), .y0(70), .x1(399), .y1(70), 
                                         .v_len(5), .dir(0), .pixel(ar_bus_acc) );
     //ALU -> BUS                                    
     arrows ar_alu_bus_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(335), .y0(147), .x1(399), .y1(147), 
                                         .v_len(5), .dir(1), .pixel(ar_alu_bus) );
     //BUS -> B REGISTER                                
     arrows ar_bus_breg_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(335), .y0(233), .x1(399), .y1(233), 
                                         .v_len(5), .dir(0), .pixel(ar_bus_breg) );
     //BUS -> OUTPUT REGISTER                                
     arrows ar_bus_outreg_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(335), .y0(319), .x1(399), .y1(319), 
                                         .v_len(5), .dir(0), .pixel(ar_bus_outreg) );
     //MAR -> RAM                                
    arrows mar_ram_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(147), .y0(184), .x1(147), .y1(197), 
                                         .v_len(5), .dir(3), .pixel(ar_mar_ram) );
     //B REG -> ALU                                    
     arrows breg_alu_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(493), .y0(183), .x1(493), .y1(197), 
                                         .v_len(5), .dir(2), .pixel(ar_breg_alu) );
     //ACC -> ALU                                
     arrows acc_alu_inst ( .pixel_x (pixel_x), .pixel_y (pixel_y), .x0(493), .y0(96), .x1(493), .y1(111), 
                                         .v_len(5), .dir(3), .pixel(ar_acc_alu) );
                                        
    
      
     wire any_arrows =     ar_pc_bus | ar_bus_pc | ar_bus_mar | ar_ram_bus | ar_bus_ram | ar_ir_bus | ar_bus_ir
									| ar_ir_control | ar_acc_bus | ar_bus_acc | ar_alu_bus | ar_bus_breg | ar_bus_outreg
									| ar_mar_ram | ar_breg_alu | ar_acc_alu;
                            
    reg [3:0] red_arrow, green_arrow, blue_arrow;
    wire arrow_is_active;

	assign arrow_is_active = 
    (ar_pc_bus && sig_pc_out) |
	(ar_bus_pc && sig_jmp)    |
	(ar_ir_bus && sig_ir_out) |
    (ar_bus_ir && sig_ir_in)  |
    (ar_ir_control && sig_ir_in) |
	(ar_acc_bus && sig_acc_out) |
	(ar_bus_acc && sig_acc_in) |
	(ar_alu_bus && sig_alu_out) |
	(ar_bus_mar && sig_mar_in) |
    (ar_ram_bus && sig_ram_out) |
	(ar_bus_ram && sig_ram_in) |
	(ar_bus_breg && sig_br_in) |
	(ar_bus_outreg && sig_opr_in);

	always @(*)
		{red_arrow, green_arrow, blue_arrow} = arrow_is_active ? {4'hF, 4'h0, 4'h0} : {4'hF, 4'hF, 4'hF};  

    // ============================================================
    // CONVERSÃO DE DADOS
    // ============================================================
  
    wire [31:0] pc_ascii, mar_ascii;
    wire [63:0] ir_ascii, acc_ascii, alu_ascii, breg_ascii, output_reg_ascii;
 
    bin_to_ascii #(.N(4)) c_pc  (.binary_in(pc_bin),   .ascii_out(pc_ascii));
    bin_to_ascii #(.N(4)) c_mar (.binary_in(mar_bin),  .ascii_out(mar_ascii));
    bin_to_ascii #(.N(8)) c_ir  (.binary_in(ir_bin),   .ascii_out(ir_ascii));
    bin_to_ascii #(.N(8)) c_acc (.binary_in(acc_bin),  .ascii_out(acc_ascii));
    bin_to_ascii #(.N(8)) c_alu (.binary_in(alu_bin),  .ascii_out(alu_ascii));
    bin_to_ascii #(.N(8)) c_br  (.binary_in(breg_bin), .ascii_out(breg_ascii));
    bin_to_ascii #(.N(8)) c_opr (.binary_in(opr_bin),  .ascii_out(output_reg_ascii));

    // ============================================================
    // LÓGICA DE CONVERSAO DA RAM 
    // ============================================================
    
    reg [7:0] ram_byte;
    wire [63:0] ram_row_ascii; // 8 chars ASCII
   
    wire [3:0] ram_row_index = (pixel_y >= 235) ? (pixel_y - 235) / 8 : 4'b0;

    always @(*) begin
			ram_byte = ram_bin[(ram_row_index * 8) +: 8]; 
    end

    // Um unico conversor para toda a RAM
    bin_to_ascii #(.N(8)) ram_converter (
        .binary_in(ram_byte),
        .ascii_out(ram_row_ascii)
    );

    // ===================================================
    // LÓGICA DE TEXTO
    // ===================================================
    localparam NUM_TEXTS = 57;
    localparam NUM_TEXTS_8x16 = 18;
    
    reg [9:0] text_x [0:NUM_TEXTS-1]; 
    reg [9:0] text_y [0:NUM_TEXTS-1]; 
    reg [4:0] text_len [0:NUM_TEXTS-1]; 
    reg [8*20-1:0] text_data [0:NUM_TEXTS-1]; 

    reg pixel_on_text;
    reg [3:0] red_text, green_text, blue_text;
	 reg text_is_active;
    reg [5:0] active_text_index;
    integer char_index, bit_index, i;
    
    reg [7:0] char_code_8x16, char_code_8x8;
    reg [3:0] row_8x16;
    reg [2:0] row_8x8;
    wire [7:0] font_data_8x16, font_data_8x8;

    // Instâncias das Fontes
    font_rom_8x16 font_inst (.char_code(char_code_8x16), .row(row_8x16), .data(font_data_8x16));
    font_rom_8x8 font_inst8x8 (.char_code(char_code_8x8), .row(row_8x8), .data(font_data_8x8));

    always @(*) begin
          
        // textos estaticos com fonte 8x16:
        text_x[0] = 68;   text_y[0] = 40;   text_len[0] = 15; text_data[0] = "PROGRAM COUNTER";
        text_x[1] = 68;   text_y[1] = 127;  text_len[1] = 3;  text_data[1] = "MAR";
        text_x[2] = 68;   text_y[2] = 408;  text_len[2] = 20; text_data[2] = "INSTRUCTION REGISTER";
        text_x[3] = 415;  text_y[3] = 379;  text_len[3] = 7;  text_data[3] = "CONTROL";
        text_x[4] = 415;  text_y[4] = 299;  text_len[4] = 15; text_data[4] = "OUTPUT REGISTER";
        text_x[5] = 415;  text_y[5] = 213;  text_len[5] = 10; text_data[5] = "B REGISTER";
        text_x[6] = 415;  text_y[6] = 127;  text_len[6] = 3;  text_data[6] = "ALU";
        text_x[7] = 415;  text_y[7] = 40;   text_len[7] = 11; text_data[7] = "ACCUMULATOR";
        text_x[8] = 127;  text_y[8] = 204;  text_len[8] = 3;  text_data[8] = "RAM";
        text_x[9] = 78;   text_y[9] = 217;  text_len[9] = 7;  text_data[9] = "ADDRESS";
        text_x[10] = 150; text_y[10] = 217; text_len[10] = 4; text_data[10] = "DATA";
        
        // Conteudos dinamicos ja convertidos para ASCII
        text_x[11] = 68;  text_y[11] = 66;  text_len[11] = 4; text_data[11] = pc_ascii;
        text_x[12] = 68;  text_y[12] = 153; text_len[12] = 4; text_data[12] = mar_ascii;
        text_x[13] = 68;  text_y[13] = 433; text_len[13] = 8; text_data[13] = ir_ascii};
        text_x[14] = 415; text_y[14] = 66;  text_len[14] = 8; text_data[14] = acc_ascii};
        text_x[15] = 415; text_y[15] = 153; text_len[15] = 8; text_data[15] = alu_ascii};
        text_x[16] = 415; text_y[16] = 239; text_len[16] = 8; text_data[16] = breg_ascii};
		text_x[17] = 415; text_y[17] = 325; text_len[17] = 8; text_data[17] = output_reg_ascii};
          
          
        //Enderecos da RAM. FONTE 8x8
        text_x[18] = 78; text_y[18] = 235; text_len[18] = 4; text_data[18] = "0000";
        text_x[19] = 78; text_y[19] = 243; text_len[19] = 4; text_data[19] = "0001";
        text_x[20] = 78; text_y[20] = 251; text_len[20] = 4; text_data[20] = "0010";
        text_x[21] = 78; text_y[21] = 259; text_len[21] = 4; text_data[21] = "0011";
        text_x[22] = 78; text_y[22] = 267; text_len[22] = 4; text_data[22] = "0100";
        text_x[23] = 78; text_y[23] = 275; text_len[23] = 4; text_data[23] = "0101";
        text_x[24] = 78; text_y[24] = 283; text_len[24] = 4; text_data[24] = "0110";
        text_x[25] = 78; text_y[25] = 291; text_len[25] = 4; text_data[25] = "0111";
        text_x[26] = 78; text_y[26] = 299; text_len[26] = 4; text_data[26] = "1000";
        text_x[27] = 78; text_y[27] = 307; text_len[27] = 4; text_data[27] = "1001";
        text_x[28] = 78; text_y[28] = 315; text_len[28] = 4; text_data[28] = "1010";
        text_x[29] = 78; text_y[29] = 323; text_len[29] = 4; text_data[29] = "1011";
        text_x[30] = 78; text_y[30] = 331; text_len[30] = 4; text_data[30] = "1100";
        text_x[31] = 78; text_y[31] = 339; text_len[31] = 4; text_data[31] = "1101";
        text_x[32] = 78; text_y[32] = 347; text_len[32] = 4; text_data[32] = "1110";
        text_x[33] = 78; text_y[33] = 355; text_len[33] = 4; text_data[33] = "1111";
          
        //nomes dos sinais de controle. FONTE 8x8
        text_x[34] = 415; text_y[34] = 406; text_len[34] = 6; text_data[34] = "PC_INC";
        text_x[35] = 475; text_y[35] = 406; text_len[35] = 6; text_data[35] = "PC_OUT";
        text_x[36] = 534; text_y[36] = 406; text_len[36] = 6; text_data[36] = "MAR_IN";
        text_x[37] = 415; text_y[37] = 417; text_len[37] = 6; text_data[37] = "RAM_IN";
        text_x[38] = 474; text_y[38] = 417; text_len[38] = 7; text_data[38] = "RAM_OUT";
        text_x[39] = 534; text_y[39] = 417; text_len[39] = 5; text_data[39] = "IR_IN";
        text_x[40] = 415; text_y[40] = 428; text_len[40] = 6; text_data[40] = "IR_OUT";
        text_x[41] = 475; text_y[41] = 428; text_len[41] = 6; text_data[41] = "ACC_IN";
        text_x[42] = 534; text_y[42] = 428; text_len[42] = 7; text_data[42] = "ACC_OUT";
        text_x[43] = 415; text_y[43] = 439; text_len[43] = 7; text_data[43] = "ALU_OUT";
        text_x[44] = 475; text_y[44] = 439; text_len[44] = 3; text_data[44] = "AND";
        text_x[45] = 534; text_y[45] = 439; text_len[45] = 2; text_data[45] = "OR";
        text_x[46] = 415; text_y[46] = 450; text_len[46] = 7; text_data[46] = "ADD_SUB";
        text_x[47] = 475; text_y[47] = 450; text_len[47] = 7; text_data[47] = "XOR_NOT";
        text_x[48] = 534; text_y[48] = 450; text_len[48] = 5; text_data[48] = "BR_IN";
        text_x[49] = 415; text_y[49] = 461; text_len[49] = 6; text_data[49] = "OPR_IN";
        text_x[50] = 475; text_y[50] = 461; text_len[50] = 3; text_data[50] = "JMP";
        text_x[51] = 534; text_y[51] = 461; text_len[51] = 3; text_data[51] = "HLT";
        text_x[52] = 493; text_y[52] = 388; text_len[52] = 2; text_data[52] = "T0";
        text_x[53] = 512; text_y[53] = 388; text_len[53] = 2; text_data[53] = "T1";
        text_x[54] = 533; text_y[54] = 388; text_len[54] = 2; text_data[54] = "T2";
        text_x[55] = 553; text_y[55] = 388; text_len[55] = 2; text_data[55] = "T3";
        text_x[56] = 573; text_y[56] = 388; text_len[56] = 2; text_data[56] = "T4";
        
   
        pixel_on_text = 0;
        active_text_index = 6'd0;
        char_code_8x16 = 0; row_8x16 = 0;
        char_code_8x8 = 0; row_8x8 = 0;
        {red_text, green_text, blue_text} = {4'hF, 4'hF, 4'hF};

        if (video_on) begin
            for (i = 0; i < NUM_TEXTS_8x16; i = i + 1) begin
                if (pixel_x >= text_x[i] && pixel_x < text_x[i] + 8 * text_len[i] &&
                    pixel_y >= text_y[i] && pixel_y < text_y[i] + 16) begin
                    
                    char_index = (pixel_x - text_x[i]) / 8;
                    bit_index  = (pixel_x - text_x[i]) % 8;
                    row_8x16   = (pixel_y - text_y[i]) % 16;
                    char_code_8x16  = text_data[i][8*(text_len[i]-1-char_index) +: 8];
                    
					if (font_data_8x16[7-bit_index]) pixel_on_text = 1;
                    active_text_index = i;
                end
            end

            // 2. Textos 8x8
            for (i = NUM_TEXTS_8x16; i < NUM_TEXTS; i = i + 1) begin
                if (!pixel_on_text &&
                    pixel_x >= text_x[i] && pixel_x < text_x[i] + 8 * text_len[i] &&
                    pixel_y >= text_y[i] && pixel_y < text_y[i] + 8) begin
                    
                    char_index = (pixel_x - text_x[i]) / 8;
                    bit_index  = (pixel_x - text_x[i]) % 8;
                    row_8x8    = (pixel_y - text_y[i]) % 8;
                    char_code_8x8 = text_data[i][8*(text_len[i]-1-char_index) +: 8];
                    
					if (font_data_8x8[7-bit_index]) pixel_on_text = 1;
                    active_text_index = i;
                end
            end

            // 3. RAM ASCII 
            if (!pixel_on_text &&
                pixel_x >= 150 && pixel_x < 150 + 64 && // largura 8 chars * 8 pixels
                pixel_y >= 235 && pixel_y < 235 + 128) begin // altura 16 linhas * 8 pixels
                
                char_index = (pixel_x - 150) / 8;
                bit_index  = (pixel_x - 150) % 8;
                row_8x8    = (pixel_y - 235) % 8;
                
                char_code_8x8 = ram_row_ascii[8*(7-char_index) +: 8];
                
                if (font_data_8x8[7-bit_index]) pixel_on_text = 1;
                active_text_index = 6'd63; 
            end
        end

        // =============================
        // CORES DOS SINAIS DE CONTROLE
        // =============================
          
         text_is_active = 1'b0;
         
         if (pixel_on_text) begin
              case (active_text_index)
                  34: text_is_active = sig_pc_inc;
                  35: text_is_active = sig_pc_out;
                  36: text_is_active = sig_mar_in;
                  37: text_is_active = sig_ram_in;
                  38: text_is_active = sig_ram_out;
                  39: text_is_active = sig_ir_in;
                  40: text_is_active = sig_ir_out;
                  41: text_is_active = sig_acc_in;
                  42: text_is_active = sig_acc_out;
                  43: text_is_active = sig_alu_out;
                  44: text_is_active = sig_alu0;
                  45: text_is_active = sig_alu1;
                  46: text_is_active = sig_add_sub;
                  47: text_is_active = sig_xor_not;
                  48: text_is_active = sig_br_in;
                  49: text_is_active = sig_opr_in;
                  50: text_is_active = sig_jmp;
                  51: text_is_active = sig_hlt;
                  52: text_is_active = (ring_counter == 5'b00001);
                  53: text_is_active = (ring_counter == 5'b00010);
                  54: text_is_active = (ring_counter == 5'b00100);
                  55: text_is_active = (ring_counter == 5'b01000);
                  56: text_is_active = (ring_counter == 5'b10000);
              endcase
              
              if (text_is_active) begin
                  {red_text, green_text, blue_text} = {4'hF, 4'h0, 4'h0};
              end
              
         end
			
    end
  
    // ==========================================
    // COR DO PIXEL
    // ==========================================
    
    reg [3:0] r_color, g_color, b_color;
    
    always @(*) begin
        if (pixel_on_text)
            {r_color, g_color, b_color} = {red_text, green_text, blue_text};
        else if (any_arrows) 
            {r_color, g_color, b_color} = {red_arrow, green_arrow, blue_arrow};
        else if (any_border)
				{r_color, g_color, b_color} = {red_border, green_border, blue_border};
        else
            {r_color, g_color, b_color} = {4'h0, 4'h0, 4'h0}; // Fundo preto
    end

    // ==========================================
    // SAIDA VGA
    // ==========================================
    
	 always @(posedge clk_25mhz or posedge reset) begin
        if (reset) begin
            {red, green, blue} <= 12'h0;
            hsync <= 0;
            vsync <= 0;
        end else begin
            hsync <= hsync_comb;
            vsync <= vsync_comb;
            
            if (video_on) begin
                {red, green, blue} <= {r_color, g_color, b_color};
            end else begin
                {red, green, blue} <= 12'h0;
            end
        end
    end


endmodule 
