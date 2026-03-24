module clock_circuit (
    input  wire clock_auto,
    input  wire manual_auto,
    input  wire button_clock_manual,       // botão ativo‑baixa
    input  wire hlt,
    output wire clock
);

    assign clock =
        (hlt)              ? 1'b0 :    // se halt, sem clock
        (manual_auto)      ? clock_auto: // se manual_auto = 1, clock auto
                             button_clock_manual; // manual: pulso ao apertar
endmodule 
