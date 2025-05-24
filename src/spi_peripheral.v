`default_nettype none

module spi_peripheral (
    input wire        ncs,
    input wire        rst_n,
    input wire        sclk,
    input wire        clk,
    input wire        copi,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

reg [15:0] transaction;
reg [4:0] sclk_count;

reg sclk_sync1, sclk_sync2;
reg ncs_sync1, ncs_sync2;
reg copi_sync1, copi_sync2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        // Resetting all registers when reset is pulled low (active low)
        en_reg_out_7_0 <= '0;
        en_reg_out_15_8 <= '0;
        en_reg_pwm_7_0 <= '0;
        en_reg_pwm_15_8 <= '0;
        pwm_duty_cycle <= '0;

        transaction <= '0;
        sclk_sync2 <= '0;
        sclk_sync1 <= '0;

        ncs_sync2 <= '0;
        ncs_sync1 <= '0;

        copi_sync2 <= '0;
        copi_sync1 <= '0;
    end

    else begin
        // CDC synching for copi sclk and ncs
        // Synch chain of 2 registors for copi and ncs, 3 for sclk
        // newest 1 -> 2 -> 3 oldest
        sclk_sync2 <= sclk_sync1;
        sclk_sync1 <= sclk;

        ncs_sync2 <= ncs_sync1;
        ncs_sync1 <= ncs;

        copi_sync2 <= copi_sync1;
        copi_sync1 <= copi;

        // Start of transaction, ncs falling edge
        if(~ncs_sync2 & ncs_sync1) begin
            transaction <= '0;
            sclk_count <= '0;
        end

        // During transaction, ncs low & sclk posedge
        else if (~(ncs_sync1 | ncs_sync2) && (sclk_sync2 & ~sclk_sync2)) begin
            if (sclk_count < 5'd16) begin
                transaction[sclk_count] <= copi_sync2;
                sclk_count <= sclk_count + 1;
            end
        end

        // After transaction, ncs rising edge, writing bit high and clk = 16
        if ((sclk_count == 5'd16) && (ncs_sync1 & ~ncs_sync2) && transaction[0]) begin
            case (transaction[7:0])
                2'h00 : en_reg_out_7_0 <= transaction[15:8];
                2'h01 : en_reg_out_15_8 <= transaction[15:8];
                2'h02 : en_reg_pwm_7_0 <= transaction[15:8];
                2'h03 : en_reg_pwm_15_8 <= transaction[15:8];
                2'h04 : pwm_duty_cycle <= transaction[15:8];
                default: ;
            endcase

        end

    end
end



endmodule

