module arrows ( 
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    input [9:0] x0, y0, x1, y1,
    input [2:0] v_len,
    input [1:0] dir,       // 0:right, 1:left, 2:up, 3:down
    output reg pixel
);
    integer i;
    always @(*) begin
        pixel = 0;
        
        // Linha horizontal
        if (y0 == y1) begin
            if (pixel_y == y0 && pixel_x >= x0 && pixel_x <= x1)
                pixel = 1;
            
            // seta na ponta direita
            if (dir == 0) begin
                for (i = 1; i <= v_len; i = i + 1) begin
                    if ((pixel_x == x1-i && pixel_y == y1-i) || (pixel_x == x1-i && pixel_y == y1+i))
                        pixel = 1;
                end
            end
            // seta na ponta esquerda
            if (dir == 1) begin
                for (i = 1; i <= v_len; i = i + 1) begin
                    if ((pixel_x == x0+i && pixel_y == y0-i) || (pixel_x == x0+i && pixel_y == y0+i))
                        pixel = 1;
                end
            end
        end
        // Linha vertical
        else if (x0 == x1) begin
            if (pixel_x == x0 && pixel_y >= y0 && pixel_y <= y1)
                pixel = 1;
            
            // seta na ponta inferior
            if (dir == 3) begin
                for (i = 1; i <= v_len; i = i + 1) begin
                    if ((pixel_x == x1-i && pixel_y == y1-i) || (pixel_x == x1+i && pixel_y == y1-i))
                        pixel = 1;
                end
            end
            // seta na ponta superior
            if (dir == 2) begin
                for (i = 1; i <= v_len; i = i + 1) begin
                    if ((pixel_x == x0-i && pixel_y == y0+i) || (pixel_x == x0+i && pixel_y == y0+i))
                        pixel = 1;
                end
            end
        end
    end
endmodule
