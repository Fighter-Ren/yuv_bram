//***************************************
//Filename    : addr_test
//Author      : MaoRen
//Description : address test
//Created     : 2019-12-30
`timescale 1ns/100ps
module addr_test(
	clk,
	rst_n,
	data_valid,
	w_ready
	//r_addr
);

//===================================
//		  IO   Declaration
//===================================
input  clk;
input  rst_n;
input  data_valid;
output reg w_ready;
reg[6:0] r_addr;

//===================================
//		Variable Declaration
//===================================
reg  loadstart;

//===================================
//		Logic  Declaration
//===================================
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		r_addr <= 'b0;
	end
	else if(r_addr==7'd95&&data_valid)begin
		r_addr <= 'b0;
	end
	else if(data_valid)begin
		r_addr <= r_addr + 1'b1;
	end
	else begin
		r_addr <= r_addr;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		w_ready <= 'b0;
	end
	else if(r_addr==7'd94&&data_valid)begin
		w_ready <= 'b0;
	end
	else if(loadstart)begin
		w_ready <= 1'b1;
	end
	else begin
		w_ready <= w_ready;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		loadstart = 1'b1;
		#40 loadstart = 'b0;
	end
	else if(r_addr==7'd95&&data_valid)begin
		#80 loadstart = 1'b1;
		#20 loadstart = 1'b0;
	end
	else begin
		loadstart = loadstart;
	end
end

endmodule