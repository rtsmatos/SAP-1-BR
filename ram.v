module ram (
    input clock,          // pulso de 1 ciclo (mesmo usado no SAP)
	 input we,
    input ram_in,             // sinal de controle da UC (modo RUN)
    input ram_out,            // controle de leitura
    input prog_run,           // 0 = modo PROG, 1 = modo RUN
    input [3:0] mar_to_ram,   // endereço (MAR)
    input [7:0] bus_in,       // dado vindo do barramento
    input [7:0] prog_data, // switches do usuário (modo PROG)
    output [7:0] bus_out,
	 output [16*8 -1:0] ram_to_vga  //expondo todas as linhas da RAM
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
	 
	 //Achatar o conteudo da ram para enviar para o modulo vga
	 genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : memory_output
            assign ram_to_vga[(i+1)*8-1 -: 8] = memory[i];
        end
    endgenerate
	 
endmodule 