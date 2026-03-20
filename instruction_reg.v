module instruction_reg (
	input [7:0] bus_in,
	input clock,
	input clear,
	input ir_in,
	input ir_out,
	output [3:0] bus_out,
	output [3:0] instruction_to_control,
	output [7:0] ir_to_vga
);

	reg [7:0] data = 8'b00000000;
	
	always @(posedge clock or posedge clear) begin
		if(clear) data <= 8'b00000000;
		else if(ir_in) data <= bus_in;
	end
	
	assign bus_out = ir_out ? data[3:0] : 4'bzzzz;
	assign instruction_to_control = data[7:4];
	assign ir_to_vga = data;
	
endmodule 