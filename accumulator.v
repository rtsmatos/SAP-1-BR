module accumulator (
	input [7:0] bus_in,
	input clock,
	input clear,
	input acc_in,
	input acc_out,
	output [7:0] bus_out,
	output [7:0] acc_to_alu,
	output [7:0] acc_to_vga
);

	reg [7:0] data = 8'b00000000;
	
	always @(posedge clock or posedge clear) begin
		if(clear) data <= 8'b00000000;
		else if(acc_in) data <= bus_in;
	end
	
	assign bus_out = acc_out ? data : 8'bzzzzzzzz;
	assign acc_to_alu = data;
	assign acc_to_vga = data;
	
endmodule 