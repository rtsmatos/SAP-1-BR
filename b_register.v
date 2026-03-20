module b_register (
	input clock,
	input clear,
	input br_in,
	input [7:0] bus_in,
	output [7:0] b_to_alu,
	output [7:0] b_to_vga
);

	reg [7:0] data = 8'b00000000;
	
	always @(posedge clock or posedge clear) begin
		if(clear) data <= 8'b00000000;
		else if(br_in) data <= bus_in;
	end
	
	assign b_to_alu = data;
	assign b_to_vga = data;
endmodule 