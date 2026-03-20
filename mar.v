module mar (
	input clock,
	input clear,
	input mar_in, 
	input prog_run, //1 = run
	input [3:0] bus_in,
	input [3:0] prog_address, //endereco das chaves
	output [3:0] mar_to_ram,  //saida do endereco para a RAM
	output [3:0] mar_to_vga
);
	
	reg [3:0] data = 4'b0000;
	always @ (posedge clock or posedge clear) begin
		if(clear) data <= 4'b0000;
		else if(mar_in) data <= bus_in;
	end
	
	assign mar_to_ram = prog_run ? data : prog_address;
	assign mar_to_vga = data;
	
endmodule 