module alu (

	input alu_out,
	input add_sub,
	input alu0_and,
	input alu1_or,
	input xor_not,
	input [7:0] acc_to_alu, //entrada que vem do acumulador
	input [7:0] b_to_alu,   //entrada que vem do b register
	output [7:0] bus_out,  //saida para o barramento
	output [7:0] alu_to_vga
	
);

	reg [7:0] data = 8'b00000000;
	wire [3:0] operation_select = {xor_not,add_sub,alu1_or,alu0_and};
	
	always@(*) begin
		casez(operation_select) 
				4'b?000: data = acc_to_alu + b_to_alu;
				4'b?100:	data = acc_to_alu - b_to_alu;
				4'b??01: data = acc_to_alu & b_to_alu;
				4'b??10: data = acc_to_alu | b_to_alu;
				4'b0?11: data = acc_to_alu ^ b_to_alu;
				4'b1?11: data = ~acc_to_alu;
				default: data = 8'b00000000;
			endcase
	end
	
	assign bus_out = alu_out ? data : 8'bzzzzzzzz;
	assign alu_to_vga = data;

endmodule	