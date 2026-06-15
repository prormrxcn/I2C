`timescale 1ns / 1ps

module i2c_tb;
    parameter address_width = 8;
    parameter data = 8;
    
    wire [7:0] sda;
    wire scl;
    reg clk;
    reg rst_n;
    reg [address_width-1:0] address;
    
    i2c #(
        .address_width(address_width),
        .data(data)
    ) uut (
        .sda(sda),
        .scl(scl),
        .clk(clk),
        .rst_n(rst_n),
        .address(address)
    );
    
    reg [7:0] sda_drive;
    reg sda_oe;
    
    assign sda = sda_oe ? sda_drive : 8'bz;
    
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    initial begin
        $monitor("Time=%0t, scl=%b, sda=%b, address=%h, read=%b, write=%b, bit_counter=%d, adress_state=%b, stop=%b, start=%b", 
                 $time, scl, sda, uut.address_reg, uut.read, uut.write, uut.bit_counter, uut.adress_state, uut.stop, uut.start);
    end
    
    initial begin
        rst_n = 0;
        address = 8'hA0;
        sda_oe = 0;
        sda_drive = 8'bz;
        
        #100;
        rst_n = 1;
        #50;
        
        $display("\n=== Test 1: START Condition ===");
        simulate_start();
        #200;
        
        $display("\n=== Test 2: Address Write ===");
        send_byte(8'hA0, 1);
        #500;
        
        $display("\n=== Test 3: Data Write ===");
        send_byte(8'h55, 1);
        #500;
        
        $display("\n=== Test 4: STOP Condition ===");
        simulate_stop();
        #500;
        
        $display("\n=== Test 5: Address Read ===");
        simulate_start();
        send_byte(8'hA1, 1);
        #500;
        
        $display("\n=== Test 6: Data Read ===");
        receive_byte(8'hAA);
        #500;
        
        $display("\n=== Test 7: Final STOP ===");
        simulate_stop();
        #500;
        
        $display("\n=== Test 8: Multiple Transactions ===");
        for(int i = 0; i < 3; i++) begin
            simulate_start();
            send_byte(8'hA0, 1);
            send_byte(8'h30 + i, 1);
            simulate_stop();
            #300;
        end
        
        $display("\n=== Test Complete ===");
        #500;
        $finish;
    end
    
    task simulate_start();
        begin
            sda_oe = 1;
            sda_drive = 8'b0;
            #40;
            #100;
            sda_oe = 0;
        end
    endtask
    
    task simulate_stop();
        begin
            sda_oe = 1;
            sda_drive = 8'b0;
            #20;
            sda_oe = 0;
            #40;
        end
    endtask
    
    task send_byte(input [7:0] byte_data, input expect_ack);
        begin
            sda_oe = 1;
            for(int i = 7; i >= 0; i--) begin
                wait(scl == 0);
                #5;
                if(byte_data[i])
                    sda_drive = 8'bz;
                else
                    sda_drive = 8'b0;
                wait(scl == 1);
                #40;
            end
            wait(scl == 0);
            #5;
            if(expect_ack)
                sda_drive = 8'b0;
            else
                sda_drive = 8'bz;
            wait(scl == 1);
            #40;
            sda_oe = 0;
            #20;
        end
    endtask
    
    task receive_byte(input [7:0] slave_response);
        begin
            sda_oe = 1;
            for(int i = 7; i >= 0; i--) begin
                wait(scl == 0);
                #5;
                if(slave_response[i])
                    sda_drive = 8'bz;
                else
                    sda_drive = 8'b0;
                wait(scl == 1);
                #40;
            end
            wait(scl == 0);
            #5;
            sda_drive = 8'b0;
            wait(scl == 1);
            #40;
            sda_oe = 0;
            #20;
        end
    endtask
    
    initial begin
        $dumpfile("i2c_tb.vcd");
        $dumpvars(0, i2c_tb);
    end
    
endmodule