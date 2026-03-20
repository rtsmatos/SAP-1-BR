module font_rom_8x16 (
    input  wire [7:0] char_code,   // ASCII
    input  wire [3:0] row,         // linha do caractere 
    output reg  [7:0] data         // pixels da linha
);
    reg [7:0] font_mem [0:4095];   // 256 caracteres x 16 linhas = 4096 bytes

    initial begin
        $readmemh("IBM_VGA_8x16.hex", font_mem);
    end

    always @(*) begin
        data = font_mem[{char_code, row}];
    end
endmodule 
