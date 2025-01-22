module pwm4gen
#(
    parameter N = 50,           // fdiv 模块中的计数值
    parameter NW = 6,           // fdiv 模块中的计数器宽度
    parameter NUM = 9_9999_9999 // cnt 模块中的最大计数值
)
(
    input clk, 
    input reset_n, 
    input load, 
    input [31:0] d, 
    input [31:0] s0, s1, s2, s3, p0, p1, p2, p3, 
    output reg x0, x1, x2, x3
);
    wire pclk;  // 由 fdiv 模块输出的低频时钟
    wire [31:0] q;  // 由 cnt 模块输出的计数值

    // 实例化 fdiv 模块，生成 `pclk` 信号
    fdiv i_fdiv (
        .clk(clk),
        .reset_n(reset_n),
        .pclk(pclk)
    );

    // 实例化 cnt 模块，生成计数值 `q`
    cnt i_cnt (
        .clk(clk),
        .en(pclk),
        .reset_n(reset_n),
        .load(load),
        .d(d),
        .q(q)
    );

    // 生成 PWM 输出信号，根据计数值 `q` 和比较值来控制输出
    always @(posedge clk or negedge reset_n)
        if (!reset_n) begin
            x0 <= 1'b0;
            x1 <= 1'b0;
            x2 <= 1'b0;
            x3 <= 1'b0;
        end 
		else 
		begin
            // 默认将 PWM 输出设为低电平
            x0 <= 1'b0;
            x1 <= 1'b0;
            x2 <= 1'b0;
            x3 <= 1'b0;
            
            // 根据计数值 `q` 和设定的比较值，生成高电平
            if ((q >= s0) && (q < p0)) x0 <= 1'b1;
            if ((q >= s1) && (q < p1)) x1 <= 1'b1;
            if ((q >= s2) && (q < p2)) x2 <= 1'b1;
            if ((q >= s3) && (q < p3)) x3 <= 1'b1;
        end
endmodule

module fdiv
#(
    parameter N = 50,    // 计数器的最大值
    parameter NW = 6     // 计数器的位宽
)
(
    input clk, 
    input reset_n, 
    output reg pclk
);
    reg [NW-1:0] cnt;  // 计数器

    // 计数器的行为：在时钟的上升沿（`posedge clk`）或者复位信号的下降沿（`negedge reset_n`）时更新计数器值。
    always @(posedge clk or negedge reset_n)
        if (!reset_n)
            cnt <= 0;  // 如果复位信号有效，则清零计数器
        else if (cnt < N-1)
            cnt <= cnt + 1'b1;  // 否则，计数器加1，直到达到最大值 N-1
        else
            cnt <= 0;  // 如果计数器已达到最大值，则重新从0开始计数

    // 控制输出脉冲 `pclk`：当计数器等于1时，输出一个高脉冲，其他时候输出低脉冲
    always @(posedge clk or negedge reset_n)
        if (!reset_n)
            pclk <= 1'b0;  // 如果复位信号有效，`pclk` 为低
        else if (cnt == 1)
            pclk <= 1'b1;  // 如果计数器等于1，`pclk` 为高
        else
            pclk <= 1'b0;  // 否则，`pclk` 为低
endmodule


// cnt 模块
module cnt
#(
    parameter NUM = 9_9999_9999  // 最大计数值
)
(
    input clk, en, load, reset_n,  // 输入信号：时钟，启用信号，加载信号，复位信号
    input [31:0] d,  // 计数器的加载值
    output reg [31:0] q  // 计数器输出
);
    reg [31:0] qmax;  // 计数器的最大值

    // 更新最大计数值 `qmax`，在 `load` 信号为有效时，根据 `d` 的值来设置最大计数值。
    always @(posedge clk or negedge reset_n)
        if (!reset_n)
            qmax <= 0;  // 如果复位信号有效，则 `qmax` 为0
        else if (load)
            qmax <= (d > NUM) ? NUM : d;  // 如果加载信号有效，则 `qmax` 设置为 `d` 或者 `NUM`（取较小值）

    // 根据 `en` 和计数器值 `q` 来控制计数器的递增
    always @(posedge clk or negedge reset_n)
        if (!reset_n)
            q <= 0;  // 如果复位信号有效，则 `q` 清零
        else if (en)  // 如果启用信号有效，则开始计数
            if (q < qmax)
                q <= q + 1;  // 如果计数器未到达最大值，则递增
            else
                q <= 0;  // 如果计数器到达最大值，则清零
endmodule

