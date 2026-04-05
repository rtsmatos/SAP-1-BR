module control (
    input [3:0] instruction,
    input clock,
    input clear,
	 output reg [4:0] vga_ring_counter,
    output reg pc_inc, jmp, pc_out, acc_in, acc_out, mar_in, alu_out, 
               add_sub, alu0_and, alu1_or, xor_not, ram_in, ram_out, 
               br_in, ir_in, ir_out, opr_in, hlt_sig
);

    localparam LDA = 4'b0001, LDI = 4'b0010, STA = 4'b0011, ADD = 4'b0100,
               SUB = 4'b0101, AND = 4'b0110, OR  = 4'b0111, XOR = 4'b1000,
               NOT = 4'b1001, JMP = 4'b1010, OUT = 4'b1110, HLT = 4'b1111;

    localparam T0 = 5'b00001, T1 = 5'b00010, T2 = 5'b00100, 
               T3 = 5'b01000, T4 = 5'b10000;
					
    reg [4:0] ring_counter = T0;
	 
	always @(posedge clock or posedge clear) begin
	 
        if (clear) begin
            ring_counter <= T0;
			vga_ring_counter <= T0;
            
            {pc_inc, jmp, pc_out, acc_in, acc_out, mar_in, alu_out, add_sub, 
             alu0_and, alu1_or, xor_not, ram_in, ram_out, br_in, ir_in, 
             ir_out, opr_in, hlt_sig} <= 18'b0;
        
		  end else begin
            // Zera todos os sinais a cada inicio de periodo T
            {pc_inc, jmp, pc_out, acc_in, acc_out, mar_in, alu_out, add_sub, 
             alu0_and, alu1_or, xor_not, ram_in, ram_out, br_in, ir_in, 
             ir_out, opr_in, hlt_sig} <= 18'b0;
				 
			vga_ring_counter <= ring_counter;

           
            case (ring_counter)
                T0: begin pc_out <= 1; mar_in <= 1; end
                T1: begin pc_inc <= 1; ram_out <= 1; ir_in <= 1; end
                T2: begin
                    case (instruction)
                        LDA, STA, ADD, SUB, AND, OR, XOR: begin ir_out <= 1; mar_in <= 1; end
                        LDI: begin ir_out <= 1; acc_in <= 1; end
                        JMP: begin ir_out <= 1; jmp <= 1; end
                        OUT: begin acc_out <= 1; opr_in <= 1; end
                        NOT: begin alu_out <= 1; acc_in <= 1; alu1_or <= 1; alu0_and <= 1; xor_not <= 1; end
                        HLT: begin hlt_sig <= 1; end
                    endcase
                end
                T3: begin
                    case (instruction)
                        LDA: begin ram_out <= 1; acc_in <= 1; end
                        STA: begin acc_out <= 1; ram_in <= 1; end
                        ADD, SUB, AND, OR, XOR: begin ram_out <= 1; br_in <= 1; end
                    endcase
                end
                T4: begin
                    case (instruction)
                        ADD: begin alu_out <= 1; acc_in <= 1; end
                        SUB: begin alu_out <= 1; acc_in <= 1; add_sub <= 1; end
                        AND: begin alu_out <= 1; acc_in <= 1; alu0_and <= 1; end
                        OR:  begin alu_out <= 1; acc_in <= 1; alu1_or <= 1; end
                        XOR: begin alu_out <= 1; acc_in <= 1; alu1_or <= 1; alu0_and <= 1; end
                    endcase
                end
            endcase
					
				//avanca o ring counter
            if (ring_counter == T4)
                ring_counter <= T0;
            else
                ring_counter <= ring_counter << 1;
        end 
    end
	 
endmodule 
