module output_reg (
	input clock,
	input clear,
	input opr_in,
	input [7:0] bus_in,
	output [7:0] saida_sap,
	output [7:0] outputreg_to_vga
);
	
	reg [7:0] data = 8'b0;
	
	always @(posedge clock or posedge clear) begin //isso aqui talvez de errado. tenho que ver esses posedge
		if(clear) data <= 8'b00000000;
		else if(opr_in) data <= bus_in;
	end
	
	assign saida_sap = data;
	assign outputreg_to_vga = data;

endmodule 