`timescale 1ns/1ns

`define Comment(sentence) \
$display("%0s(%0d) %0s.", `__FILE__, `__LINE__, sentence)
`define MessageOK(name, value) \
$display("%0s(%0d) OK:Assertion %0s = %0d.", `__FILE__, `__LINE__, name, value)
`define MessageERROR(name, variable, value) \
$error("%0s(%0d) ERROR:Assertion %0s = %0d failed. %0s = %0d", `__FILE__, `__LINE__, name, value, name, variable)
`define ChkValue(name, variable, value) \
    if ((variable)===(value)) \
        `MessageOK(name, value); \
    else \
        `MessageERROR(name, variable, value);

module TB_I2C_TARGET_IF ;

// Simulation module signal
bit RESET_n;
bit CLK;
bit ACC_WR;
bit ACC_RD;
bit FIFO_EMPTY;
bit FIFO_FULL;
bit[7:0] ACC_WDATA;
bit[7:0] ACC_RDATA;
bit SCL;
bit SDA_IN;
bit SDA_OUT;

// Parameter
parameter ClkCyc    = 10;       // Signal change interval(10ns/50MHz)
parameter ResetTime = 20;       // Reset hold time

parameter I2cSclHalf = 625;    // SCL 1/4 period(2500ns/400KHz)

I2C_TARGET_IF U_I2C_TARGET_IF (
    .*,
    .RESET_n(RESET_n),
    .CLK(CLK),
    .ACC_WR(ACC_WR),
    .ACC_RD(ACC_RD),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_FULL(FIFO_FULL),
    .ACC_WDATA(ACC_WDATA),
    .ACC_RDATA(ACC_RDATA),
    .SCL_IN(SCL),
    .SDA_IN(SDA_IN),
    .SDA_OUT(SDA_OUT)
);


task i2c_start_condition;
    SDA_IN = 0;
    #(I2cSclHalf);
    @(posedge CLK);
    #(I2cSclHalf);
    @(posedge CLK);
    SCL = 0;
    #(I2cSclHalf);
    @(posedge CLK);
    #(I2cSclHalf);
    @(posedge CLK);
endtask

task i2c_stop_condition;
    SDA_IN = 0;
    #(I2cSclHalf);
    @(posedge CLK);
    #(I2cSclHalf);
    @(posedge CLK);
    SCL = 1;
    #(I2cSclHalf);
    @(posedge CLK);
    #(I2cSclHalf);
    @(posedge CLK);
    SDA_IN = 1;
    #(I2cSclHalf);
    @(posedge CLK);
endtask

task i2c_clk;
    SCL = 1;
    #(I2cSclHalf);
    @(posedge CLK);
    #(I2cSclHalf);
    @(posedge CLK);
    SCL = 0;
    #(I2cSclHalf);
    @(posedge CLK);
endtask

/*=============================================================================
 * Clock
 *============================================================================*/
always begin
    #(ClkCyc);
    CLK = ~CLK;
end


/*=============================================================================
 * Reset
 *============================================================================*/
initial begin
    #(ResetTime);
    RESET_n = 1;
end

initial begin
    SCL = 1;
    SDA_IN = 1;

    ACC_RD = 0;
    ACC_RDATA = 0;

    #(ResetTime);
    @(posedge CLK);

    #(I2cSclHalf);
    @(posedge CLK);

    i2c_start_condition();

    SDA_IN = 0;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 1;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 0;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 1;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 1;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 0;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 1;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 0;
     #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 1;
    #(I2cSclHalf);
    @(posedge CLK);
    `ChkValue("SDA_OUT", SDA_OUT, 0);
    `ChkValue("ACC_WR", ACC_WR, 1);
    `ChkValue("ACC_WDATA", ACC_WDATA, 8'h5A);

    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 0;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 1;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 0;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 1;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 0;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 1;
    #(I2cSclHalf);
    @(posedge CLK);
    i2c_clk();
    SDA_IN = 0;
    #(I2cSclHalf);
    @(posedge CLK);

    i2c_stop_condition();

    $finish;
end

endmodule