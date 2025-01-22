module xclock
#( parameter N = 50_000_000/100 )
(
    input clk, // 50MHz
    input reset,
    input [3:0] d,
    input [3:0] addr,
    input en,
    input load,
    output [31:0] q,
    output p_secflash,
    output p_day
);

localparam NW = $clog2(N);

reg [NW-1:0] fcnt;
reg [7:0] ten_msec, sec, minu, hour;

wire p_ten_msec = (fcnt == N-1);
assign p_secflash = (ten_msec >= 8'h49);

wire p_sec = (ten_msec == 8'h99) & p_ten_msec;
wire p_minu = (q[15:0] == 16'h5999) & p_ten_msec;
wire p_hour = (q[23:0] == 24'h595999) & p_ten_msec;
assign p_day = (q == 32'h23595900) & p_ten_msec;
assign q = {hour, minu, sec, ten_msec};

// Frequency counter
always @(posedge clk, posedge reset) begin
    if (reset)
        fcnt <= 0;
    else if (fcnt < N-1)
        fcnt <= fcnt + 1'b1;
    else
        fcnt <= 0;
end

// Ten millisecond counter
always @(posedge clk, posedge reset) begin
    if (reset)
        ten_msec <= 0;
    else if (load) begin
        if (addr == 0) ten_msec[3:0] <= d;
        if (addr == 1) ten_msec[7:4] <= d;
    end else if (en & p_ten_msec) begin
        if (ten_msec >= 8'h99)
            ten_msec <= 0;
        else if (ten_msec[3:0] >= 4'h9) begin
            ten_msec[7:4] <= ten_msec[7:4] + 1'b1;
            ten_msec[3:0] <= 0;
        end else
            ten_msec[3:0] <= ten_msec[3:0] + 1'b1;
    end
end

// Second counter
always @(posedge clk, posedge reset) begin
    if (reset)
        sec <= 0;
    else if (load) begin
        if (addr == 2) sec[3:0] <= d;
        if (addr == 3) sec[7:4] <= d;
    end else if (en & p_sec) begin
        if (sec >= 8'h59)
            sec <= 0;
        else if (sec[3:0] >= 4'h9) begin
            sec[7:4] <= sec[7:4] + 1'b1;
            sec[3:0] <= 0;
        end else
            sec[3:0] <= sec[3:0] + 1'b1;
    end
end

// Minute counter
always @(posedge clk, posedge reset) begin
    if (reset)
        minu <= 0;
    else if (load) begin
        if (addr == 4) minu[3:0] <= d;
        if (addr == 5) minu[7:4] <= d;
    end else if (en & p_minu) begin
        if (minu >= 8'h59)
            minu <= 0;
        else if (minu[3:0] >= 4'h9) begin
            minu[7:4] <= minu[7:4] + 1'b1;
            minu[3:0] <= 0;
        end else
            minu[3:0] <= minu[3:0] + 1'b1;
    end
end

// Hour counter
always @(posedge clk, posedge reset) begin
    if (reset)
        hour <= 0;
    else if (load) begin
        if (addr == 6) hour[3:0] <= d;
        if (addr == 7) hour[7:4] <= d;
    end else if (en & p_hour) begin
        if (hour >= 8'h23)
            hour <= 0;
        else if (hour[3:0] >= 4'h9) begin
            hour[7:4] <= hour[7:4] + 1'b1;
            hour[3:0] <= 0;
        end else
            hour[3:0] <= hour[3:0] + 1'b1;
    end
end

endmodule
