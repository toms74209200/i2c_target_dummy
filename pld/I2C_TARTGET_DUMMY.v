module i2c_target_dummy (
    input RESET_n,
    input CLK,
    input SCL,
    inout SDA

);

I2C_TARGET_IF U_I2C_TARGET_IF(
    .RESET_n(RESET_n),
    .CLK(CLK),
    .SCL_IN(SCL),
    .SDA(SDA)
);

endmodule