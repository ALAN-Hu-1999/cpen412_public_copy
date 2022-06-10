module IIC_SPI_BUS_Decoder(
    input unsigned [31:0] Address,
    input IOSelect_H,
    input AS_L,
    output reg IIC0_Enable
);

    always@(*) begin
        IIC0_Enable <= 0;
        if((IOSelect_H == 1) && (AS_L == 0)) begin
		    if(Address[15:4] == 12'h800)
                IIC0_Enable <= 1;
        end
    end
    
endmodule

