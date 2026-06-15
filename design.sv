// Code your design here
module i2c #(
    address_width = 8 , data = 8
) (
    inout wire [7:0] sda,
    output reg scl,
    input logic clk,
    input logic rst_n,
    input logic [address_width-1:0] address
);
    logic data_valid , adress_valid , stop;
    logic [6:0] counter;
    logic read, write;
    logic [4:0] bit_counter;
    logic adress_state;
    logic drive_low;
    logic ack_received;
    logic [data-1:0] data_reg;
    logic [address_width-1:0] address_reg;
    logic [1:0] state;
    logic sda_in;
    logic stop_generated;
    logic start_detected;

    wire start;
    wire ack;

    assign sda_in = sda[0];

    always_ff @( posedge clk or negedge rst_n ) begin : scl_tick
        if(!rst_n) begin
            scl <= 0;
            counter <= 0;
        end
        else if(counter == 9) begin
            counter <= 0;
            scl <= ~scl;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    // Continuous assignments for combinational signals
    assign start = (scl && (bit_counter <= 8) && !sda_in) ? 1'b1 : 1'b0;
    assign ack = (bit_counter == 9 && !sda_in && scl) ? 1'b1 : 1'b0;

    assign sda = (drive_low) ? 8'b0 : 8'bz;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
            drive_low <= 0;
            read <= 0;
            write <= 0;
            adress_valid <= 0;
            data_valid <= 0;
            stop <= 0;
            adress_state <= 0;
            ack_received <= 0;
            address_reg <= 0;
            data_reg <= 0;
            state <= 0;
            stop_generated <= 0;
            start_detected <= 0;
        end else if (start && (bit_counter <= 8)) begin
            bit_counter <= bit_counter + 1'b1;
            start_detected <= 1;
            if (address_reg[address_width-1]) begin
                drive_low <= 1'b0;
            end else begin
                drive_low <= 1'b1;
            end
            if (bit_counter == 8) begin
                if(sda_in == 1'b1)
                    read <= 1'b1;
                else
                    write <= 1'b1;
            end
        end else if (ack) begin
            ack_received <= 1'b1;
            bit_counter <= 0;
            drive_low <= 0;
            if(adress_state == 0) begin
                adress_state <= 1;
                adress_valid <= 1;
            end else begin
                data_valid <= 1;
            end
        end else if(adress_state && write && bit_counter < data) begin
            if(scl == 0) begin
                bit_counter <= bit_counter + 1;
                if(address[bit_counter])
                    drive_low <= 1'b1;
                else
                    drive_low <= 1'b0;
            end
        end else if(adress_state && read && bit_counter < data) begin
            if(scl == 0) begin
                bit_counter <= bit_counter + 1;
                drive_low <= 0;
            end
        end else if(bit_counter == data && scl == 0) begin
            bit_counter <= 0;
            drive_low <= 0;
            if(write) begin
                write <= 0;
                stop_generated <= 1;
            end else if(read) begin
                read <= 0;
                stop_generated <= 1;
            end
        end else if(stop_generated && scl == 1) begin
            drive_low <= 0;
            stop <= 1;
            stop_generated <= 0;
            adress_state <= 0;
            start_detected <= 0;
        end
    end
endmodule
