module SAP_1_BR (
	input manual_auto, //switch que permite escolher entre clock manual ou automatico
	input button_clock_manual, //mapeado para um push button
	input [3:0] prog_address, //chaves do fpga.
	input [7:0] prog_data, //chaves da placa
	input clock_auto, //MAX10_CLK1_50 (PIN_P11)
	input button_clear, //Push button no fpga
	input prog_run, //chave do fpga
	output [7:0] output_sap, //mostrar saida nos leds do fpga
	
	//vga
   output hsync,
   output vsync,
   output [3:0] red,
   output [3:0] blue,
   output [3:0] green
	
);

	//sinais de controle
	wire sig_pc_out, sig_pc_inc, sig_jmp, sig_acc_in, sig_acc_out, sig_mar_in, sig_ram_in, sig_ram_out, sig_alu_out,
	sig_alu0, sig_alu1, sig_add_sub, sig_xor_not, sig_br_in, sig_ir_in, sig_ir_out, sig_opr_in, sig_hlt;
	
	//wires de ligacao direta entre modulos
	wire [3:0] ir_to_control; //instrucao que sai do IR para o Control
	wire [3:0] mar_to_ram;
	wire [7:0] acc_to_alu;
	wire [7:0] b_to_alu;
	

	//barramento de 8 bits
	wire [7:0] bus;
		
	//wires de ligacao de saida dos modulos para o barramento
	wire [3:0] bus_pc;
	wire [7:0] bus_ir;
	wire [7:0] bus_acc;
	wire [7:0] bus_alu;
	wire [7:0] bus_ram;
	
	// Wires com binarios para o VGA
    wire [3:0] pc_to_vga;
    wire [3:0] mar_to_vga;
    wire [7:0] ir_to_vga;
    wire [7:0] acc_to_vga;
    wire [7:0] alu_to_vga;
    wire [7:0] b_to_vga;
    wire [7:0] outputreg_to_vga;
	 wire [4:0] vga_ring_counter;
    wire [127:0] ram_to_vga; // 16 endereços * 8 bits = 128 bits crus
	 	
	//o barramento vai receber o conteudo apenas do modulo que estiver com a saida habilitada
	assign bus = sig_pc_out ? {4'b0000, bus_pc[3:0]} :
				 sig_acc_out ? bus_acc :
				 sig_alu_out ? bus_alu :
				 sig_ir_out ? {4'b0000, bus_ir[3:0]} :
				 sig_ram_out ? bus_ram :
				 8'b00000000;
	
	wire clock; //sinal de clock distribuido para os modulos
	wire clear = ~button_clear; //Invertidos porque os botoes do fpga sao nivel alto quando SOLTOS. Quero 1 quando eu pressiona-lo

		
	clock_circuit clock_circuit (
   		.clock_auto (clock_auto),
   		.manual_auto (manual_auto),
		.button_clock_manual (~button_clock_manual), //no DE10-Lite, os botoes são nivel alto quando soltos. Quero o contrario  
   		.hlt (sig_hlt),
   		.clock (clock)
	);
	
	program_counter program_counter (
		.clock (clock),
		.pc_inc (sig_pc_inc),
		.pc_out (sig_pc_out),
		.clear (clear),
		.jmp (sig_jmp),
		.bus_in (bus),
		.bus_out (bus_pc),
		.pc_to_vga (pc_to_vga)
	);
	
	mar mar (
		.clock (clock),
		.clear (clear),
		.mar_in (sig_mar_in),
		.prog_run (prog_run),
		.bus_in (bus),
		.prog_address(prog_address),
		.mar_to_ram (mar_to_ram),
		.mar_to_vga (mar_to_vga)
	);
	
	ram ram (
		.clock (clock),
		.we (~button_clock_manual), //no modo PROG, esse botao vai servir como pulso de escrita
		.ram_in (sig_ram_in),
		.ram_out (sig_ram_out),
		.prog_run (prog_run),
		.mar_to_ram (mar_to_ram),
		.bus_in (bus),
		.prog_data (prog_data),
		.bus_out (bus_ram),
		.ram_to_vga (ram_to_vga)
	);
	
	accumulator accumulator (
		.bus_in (bus),
		.clock (clock),
		.clear (clear),
		.acc_in (sig_acc_in),
		.acc_out (sig_acc_out),
		.bus_out (bus_acc),
		.acc_to_alu (acc_to_alu),
		.acc_to_vga (acc_to_vga)
	);
	
	b_register b_register (
		.clock (clock),
		.clear (clear),
		.br_in (sig_br_in),
		.bus_in (bus),
		.b_to_alu (b_to_alu),
		.b_to_vga (b_to_vga)
	);
	
	alu alu (
		.alu_out (sig_alu_out),
		.add_sub (sig_add_sub),
		.alu0_and (sig_alu0),
		.alu1_or (sig_alu1),
		.xor_not (sig_xor_not),
		.acc_to_alu (acc_to_alu),
		.b_to_alu (b_to_alu),
		.bus_out (bus_alu),
		.alu_to_vga (alu_to_vga)
	);
	
	output_reg output_reg (
		.clock (clock),
		.clear (clear),
		.opr_in (sig_opr_in),
		.bus_in (bus),
		.saida_sap (output_sap),
		.outputreg_to_vga (outputreg_to_vga)
	);
	
	instruction_reg instruction_reg (
		.bus_in (bus),
		.clock (clock),
		.clear (clear),
		.ir_in (sig_ir_in),
		.ir_out (sig_ir_out),
		.bus_out (bus_ir),
		.instruction_to_control (ir_to_control),
		.ir_to_vga (ir_to_vga)
	);
	
	control control (
		.instruction (ir_to_control),
		.clock (clock),
		.clear (clear),
		.pc_inc (sig_pc_inc), 
		.jmp (sig_jmp), 
		.pc_out (sig_pc_out), 
		.acc_in (sig_acc_in), 
		.acc_out (sig_acc_out), 
		.mar_in (sig_mar_in), 
		.alu_out (sig_alu_out), 
		.add_sub(sig_add_sub),
		.alu0_and (sig_alu0),
		.alu1_or (sig_alu1), 
		.xor_not (sig_xor_not), 
		.ram_in (sig_ram_in), 
		.ram_out (sig_ram_out), 
		.br_in (sig_br_in), 
		.ir_in (sig_ir_in), 
		.ir_out (sig_ir_out), 
		.opr_in (sig_opr_in), 
		.hlt_sig(sig_hlt),
		.vga_ring_counter (vga_ring_counter)
	);
	
	vga vga (
		.clk_50mhz (clock_auto), //clock de 50MHz do FPGA
        .reset (clear), 
		.ring_counter (vga_ring_counter),
         
        // Entradas Binárias
        .pc_bin   (pc_to_vga),
        .mar_bin  (mar_to_vga),
        .ir_bin   (ir_to_vga),
        .acc_bin  (acc_to_vga),
        .alu_bin  (alu_to_vga),
        .breg_bin (b_to_vga),
        .opr_bin  (outputreg_to_vga),
        .ram_bin  (ram_to_vga), // 128 bits
        
        // Sinais de controle
        .sig_pc_out (sig_pc_out), .sig_pc_inc (sig_pc_inc), .sig_jmp (sig_jmp), .sig_acc_in(sig_acc_in), 
        .sig_acc_out(sig_acc_out), .sig_mar_in(sig_mar_in), .sig_ram_in(sig_ram_in), .sig_ram_out (sig_ram_out), 
        .sig_alu_out(sig_alu_out), .sig_alu0(sig_alu0), .sig_alu1(sig_alu1), .sig_add_sub(sig_add_sub), 
        .sig_xor_not (sig_xor_not), .sig_br_in (sig_br_in), .sig_ir_in(sig_ir_in), .sig_ir_out(sig_ir_out), 
        .sig_opr_in(sig_opr_in), .sig_hlt(sig_hlt),
        
        // Saídas VGA
        .hsync (hsync), 
		.vsync (vsync),
        .red (red), 
		.green (green), 
		.blue (blue)  
    );
		
		
endmodule 
