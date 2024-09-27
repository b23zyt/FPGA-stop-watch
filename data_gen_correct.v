// Generate data at every 0.1 s
module data_gen
#(
    parameter CNT_MAX = 19'd499_999,
    parameter DATA_MAX = 20'd999_999
)
(
    input wire sys_clk,
    input wire sys_rst_n,
    input wire stop,
    output reg [19:0] data,
    output wire [5:0] point,
    output reg seg_en,
    output wire sign
);

reg [18:0] cnt_ms;
reg cnt_flag;

reg running;
reg stop_delayed;
reg stop_debounced;
reg [3:0] debounce_counter; // Simple debounce counter

// Default value
assign point = 6'b000_100;
assign sign = 1'b0;

// Debounce logic for stop signal
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        stop_delayed <= 1'b1; // Initialize delayed stop to high
        stop_debounced <= 1'b1; // Initialize debounced signal to high
        debounce_counter <= 4'b0; // Reset debounce counter
    end else begin
        if (stop != stop_debounced) begin
            debounce_counter <= debounce_counter + 1'b1; // Increment counter
            if (debounce_counter == 4'b1111) begin // If counter reaches threshold
                stop_debounced <= stop; // Update debounced signal
                debounce_counter <= 4'b0; // Reset counter
            end
        end else begin
            debounce_counter <= 4'b0; // Reset if stable
        end
        stop_delayed <= stop_debounced; // Update delayed stop
    end
end

// Running state control on falling edge of stop
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        running <= 1'b1; // Start in running state
    else if (stop_delayed && (!stop_debounced)) // Detect falling edge
        running <= ~running; // Toggle running state
end

// Count milliseconds
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_ms <= 19'd0;
    else if (!running)
        cnt_ms <= cnt_ms; // Keep the count if paused
    else if (cnt_ms == CNT_MAX)
        cnt_ms <= 19'd0; // Reset count
    else    
        cnt_ms <= cnt_ms + 1'b1;
end

// Generate count flag
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_flag <= 1'b0;
    else if (cnt_ms == CNT_MAX - 1)
        cnt_flag <= 1'b1;
    else
        cnt_flag <= 1'b0;
end

// Data generation
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        data <= 20'd0;
    else if ((data == DATA_MAX) && (cnt_flag == 1'b1))
        data <= 20'd0; // Reset data when max reached
    else if (cnt_flag == 1'b1)
        data <= data + 1'b1; // Increment data
end

// Segment enable signal
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        seg_en <= 1'b0;
    else 
        seg_en <= 1'b1;
end

endmodule
