module ram (
    input clock,     
	 input we,
    input ram_in, //sinal de escrita no modo RUN
    input ram_out,  
    input prog_run,  // 0 = modo PROG, 1 = modo RUN
	input [3:0] mar_to_ram,  // endereço recebido do MAR
    input [7:0] bus_in,       // dado vindo do barramento
    input [7:0] prog_data, // switches do usuário (modo PROG)
    output [7:0] bus_out,
	output [127:0] ram_to_vga  //recebe todo o conteudo da RAM em apenas 1 vetor de 128 bits
);

    reg [7:0] memory[0:15];
	 
	 initial begin
		$readmemb("ram.mem", memory);
	 end

	 wire clock_always = prog_run ? clock : we;

    always @(posedge clock_always) begin
        if (!prog_run) //MODO PROG
            memory[mar_to_ram] <= prog_data;
        else if (prog_run && ram_in) //Modo RUN e sinal de controle RAM_IN
            memory[mar_to_ram] <= bus_in;

    end

    assign bus_out = ram_out ? memory[mar_to_ram] : 8'bzzzzzzzz;
	 
	always @(*) begin
	    integer j;
	    for (j = 0; j < 16; j = j + 1) begin
	        ram_to_vga[j*8 +: 8] = memory[j];
	    end
	end
	 
endmodule 
