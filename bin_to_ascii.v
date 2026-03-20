module bin_to_ascii #(
    parameter N = 8
)(
    input  wire [N-1:0] binary_in,
    output reg  [8*N-1:0] ascii_out
);
    integer i;
    always @(*) begin
        for (i = 0; i < N; i = i + 1)
            ascii_out[8*(N-i)-1 -: 8] = binary_in[N-1-i] ? "1" : "0";
    end
endmodule 