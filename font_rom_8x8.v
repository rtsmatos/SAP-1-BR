module font_rom_8x8 (
    input  wire [7:0] char_code,   // ASCII (0-255)
    input  wire [2:0] row,         // linha do caractere (0-7)
    output reg  [7:0] data         // pixels da linha
);
    reg [7:0] font_mem [0:2047];   // 256 caracteres x 8 linhas = 2048 bytes

    initial begin
        $readmemh("IBM_VGA_8x8.hex", font_mem);
    end

    always @(*) begin
        data = font_mem[{char_code, row}];
    end
endmodule 