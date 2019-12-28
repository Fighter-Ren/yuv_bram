//*************************************************
//Filename      : top_tb.v
//Author        : MaoRen
//Description   : test bench for yuv_ram
//Created       : 2019-12-25
//*************************************************
`timescale 1ns/100ps

module top_tb;

parameter FILE_IN  = "four_b.dat"; //input data file
parameter FILE_OUT = "four_o.dat"; //output data file 

integer f_out;
reg clk;
reg rst_n;

reg[7:0] pixel_ram[1<<24:0];//ram for video

//ports declaration

reg[7:0]  data_in;
reg       data_en;
reg[6:0]  r_addr;
wire      w_ready;
reg     r_ready;
wire      r_valid;
wire[31:0] data_o;

//assign r_ready = 1'b1;

//initial clk and reset
initial begin
	clk = 1'b0;
	forever #10 clk = ~clk;
end

initial begin
	rst_n = 1'b0;
	#20 rst_n = 1'b1;//one clk 
end

//test bench logic

//read data into memory
reg[24:0] w_addr;

initial begin
	$readmemh(FILE_IN,pixel_ram);
	$display("0x00: %h", pixel_ram[25'h00]);
	$display("0x00: %h", pixel_ram[25'h03]);
	$display("0x00: %h", pixel_ram[25'h1517fe]);
	$display("0x00: %h", pixel_ram[25'h1517ff]);
end


//data 
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		data_in <= 'b0;
		data_en <= 'b0;
	end
	else if(w_ready)begin
		if(w_addr==25'd1382399)begin
			data_in <= 'b0;
			data_en <= 'b0;
		end
		else begin
			data_in <= pixel_ram[w_addr];
			data_en <= 'b1;
		end
	end
	else begin
		data_in <= 'b0;
		data_en <= 'b0;
	end
end
//address
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		w_addr <= 'b0;
	end
	else if(w_ready)begin
		if(w_addr == 25'd1382399)
			w_addr <= w_addr;
		else
			w_addr <= w_addr + 1'b1;
	end
	else
		w_addr <= w_addr;
end


//write data into file

initial begin
	f_out = $fopen(FILE_OUT,"wb");
end
 
//reg[6:0] r_addr;
/*reg[7:0] data_r;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		data_r <= 'b0;
	end
	else if(r_ready)begin
		if(r_valid)begin
			data_r <= data_o;
		end
		else begin
			data_r <= 'b0;
		end
	end
	else begin
		data_r <= 'b0;
	end
end*/

reg[11:0] macro_cnt;
//address
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		r_addr <= 'b0;
		macro_cnt <= 'b0;
	end
	else if(r_ready)begin
		if(r_valid)begin
			if(r_addr!=7'd95)begin
				r_addr <= r_addr + 1'b1;
				
			end
			else begin
				r_addr <= 'b0;
				macro_cnt <= macro_cnt + 1'b1;
			end
		end
		else
		r_addr <= r_addr;
	end
	else
		r_addr <= r_addr;
end

//data
always @(posedge clk)begin
    if(r_valid&&r_ready)begin
		$fwrite(f_out, "%c", data_o[31:24]);
		$fwrite(f_out, "%c", data_o[23:16]);
		$fwrite(f_out, "%c", data_o[15:8]);
		$fwrite(f_out, "%c", data_o[7:0]);
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		r_ready <= 1'b1;
	end
	else if(macro_cnt == 12'd3600)begin
		r_ready <= 1'b0;
		#100 $stop;
	end
	else begin
		r_ready <= r_ready;
	end
end


//instance of yuv_ram

yuv_ram u_yuv_ram(
	.clk        (clk      ),
	.rst_n      (rst_n    ),
	.data_in    (data_in  ), //write data yuv420
	.data_en    (data_en  ), //write enable
	.r_addr     (r_addr   ), //read address
	.w_ready    (w_ready  ),
	.r_ready    (r_ready  ),   //read enable
	.data_flag  (r_valid  ),  //data is available to output
	.data_o     (data_o   )
);

	
endmodule