// Asynchronous read: read data is available in the same cycle
// Synchronous write: write takes one cycle

module reg_file (
    input clk,
    input w_en,
    input [4:0] r_indx1, r_indx2, w_indx,
    input [31:0] w_data,
    output [31:0] r_data1, r_data2
);
    // 32 registors
    parameter DEPTH = 32;
    // each 32 bits wide
    reg [31:0] mem [0:DEPTH-1];
    
    // Asynchronous read 
    // x0 is hardwired to 0
    assign r_data1 = (r_indx1 == 5'd0) ? 32'd0 : mem[r_indx1];
    assign r_data2 = (r_indx2 == 5'd0) ? 32'd0 : mem[r_indx2];
    
    // Synchronous write 
    alw_indxys @(posedge clk) begin
        if (w_en && w_indx != 5'd0) begin
            mem[w_indx] <= w_data;
        end
    end
    
endmodule
