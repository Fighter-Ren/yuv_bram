//*******************************************************
//Filename    : yuv_bram.v
//Author      : MaoRen
//Description : RAM to store yuv and chage it to fit H264
//Created     : 2019-12-27
//*******************************************************
module yuv_ram(
	clk,
	rst_n,
	data_in,
	w_valid,
	r_addr_i,
	r_ready,
	w_ready,
	r_valid,
	data_valid,
	data_o
);
//======================================
//        Parameter Declaration
//======================================
parameter YALL_LENTH   = 1280-1; //the length of all y raw
parameter YUV_LENGTH   = YALL_LENTH*2+1; //the length of yuyv raw
parameter HMACRO_CNT   = (YALL_LENTH+1)/16-1; //the macro count of horizon 80-1
parameter Y_RAM_SIZE   = 40960; //ram size for y
parameter UV_RAM_SIZE  = 20480; //ram size for uv
parameter DATA_WIDTH_I = 8; //input data width 
parameter DATA_WIDTH_O = 32; //output data width
parameter MACRO_WIDTH  = 7; //macro block of horizon count width
parameter P_CNT_WIDTH  = 12; //2560 yuv for 1 raw most
parameter H_CNT        = 15; //16-1 raw count
parameter Y_CNT        = 64; //y count 256/4 1 macro block
parameter Y_ADDR_WIDTH = 16; //40960 is enough
parameter UV_ADDR_WIDTH= 15; //20480 is enough
//======================================
//         IO   Declaration
//======================================
input                    clk;
input                    rst_n;
input[DATA_WIDTH_I-1:0]  data_in; //input data
input                    w_valid; //input data is valid
input[6:0]               r_addr_i;  //address to read data from ram
input                    r_ready; //other module is ready to read data
output                   w_ready; //ram is ready to write
output                   r_valid; //output data is valid to read
output reg               data_valid; //output data is valid
output[DATA_WIDTH_O-1:0] data_o;  //output data

//=======================================
//      Variables Declaration
//=======================================
//common variables
reg[DATA_WIDTH_I-1:0]  y_ram [Y_RAM_SIZE-1:0]; //ram for y
reg[DATA_WIDTH_I-1:0]  uv_ram[UV_RAM_SIZE-1:0]; //ram for uv

//write operation variables
reg[Y_ADDR_WIDTH-1:0]  y_addr_s; //store address for y
reg[UV_ADDR_WIDTH-1:0] uv_addr_s; //store address for uv
reg                    h_flag; //0 is odd,1 is even raw number
wire                   h_complete; //1:store 1 raw data is finished
reg                    yuv_flag; //0 is y, 1 is uv
reg[P_CNT_WIDTH-1:0]   p_cnt; //pixel count of 1 raw
reg[3:0]               h_cnt; //input raw number
reg                    buf_valid; //1:store 1 buff complete
reg                    w_flag; //to start write
//read operation variables
wire[Y_ADDR_WIDTH-1:0]  y_addr_o; //output address for y
wire[UV_ADDR_WIDTH-1:0] uv_addr_o; //output address for uv
wire[Y_ADDR_WIDTH-1:0] addr_o_r; //output address register
wire[Y_ADDR_WIDTH-1:0] yaddr_o_r; //output y address register
wire[Y_ADDR_WIDTH-1:0] uvaddr_o_r;//output uv address register
reg[DATA_WIDTH_O-1:0]  data_y_o; //y data to output
reg[DATA_WIDTH_O-1:0]  data_uv_o;//uv data to output
reg                    out_complete; //output 1 buf complete 
reg[MACRO_WIDTH-1:0]   macro_cnt; //macro block count to output 
wire                   ram_flag; //0: y ram to output 1: uv ram to output
reg[3:0]               hy_cnt_o; //output y raw number 16
reg[1:0]               byte_cnt; //4 bytes per time
reg[2:0]			   huv_cnt_o;//output uv raw number 8
reg[6:0]               r_addr;
reg                    buf_num; //buf number

//=======================================
//        Logic   Declaration
//=======================================
//******input logic******
//state
//write enable
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		w_flag <= 1'b0;
	end
	else if(w_valid)begin
		w_flag <= 1'b1;
	end
	else begin
		w_flag <= w_flag;
	end
end
//buff control
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		buf_valid <= 'b0;
	end
	else if(h_complete&&(h_cnt==H_CNT))begin //store 1 raw data finished
		buf_valid <= 1'b1;
	end
	else if(out_complete)begin
		buf_valid <= 'b0;
	end
	else begin
		buf_valid <= buf_valid;
	end
end
assign w_ready = (!w_flag)||(y_addr_s!=y_addr_o);
assign r_valid = buf_valid; //enable to be read by other module
//raw control
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		h_flag <= 'b0;
		h_cnt  <= 'b0;
	end
	else if(h_complete)begin //store 1 raw data finished
		h_flag <= ~h_flag;
		h_cnt  <= h_cnt + 1'b1;
	end
	else begin
		h_flag <= h_flag;
		h_cnt  <= h_cnt;
	end
end

assign h_complete = !h_flag&&(p_cnt==YUV_LENGTH)||h_flag&&(p_cnt==YALL_LENTH);
//write state control
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		yuv_flag <= 'b0;
		p_cnt    <= 'b0;
	end
	else if(w_ready&&w_valid)begin //input data is valid
		case(h_flag) 
			0:begin  //input data is yuyv...
				yuv_flag <= ~yuv_flag; 
				if(p_cnt == YUV_LENGTH)begin//store yuyv raw finished
					p_cnt <= 'b0;
				end
				else begin
					p_cnt <= p_cnt + 1'b1;
				end
			end
			1:begin  //input data is yyyy...
				yuv_flag <= yuv_flag; //all is y
				if(p_cnt == YALL_LENTH)begin //store yyyy raw finished
					p_cnt <= 'b0;
				end
				else begin
					p_cnt <= p_cnt + 1'b1;
				end
			end
			default:begin
				yuv_flag <= yuv_flag;
				p_cnt    <= p_cnt;
			end
		endcase
	end
	else begin
		yuv_flag <= yuv_flag;
		p_cnt    <= p_cnt;
	end
end
//address
//y address
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		y_addr_s <= 'b0;
	end
	else if(w_ready&&w_valid&&!yuv_flag)begin//input data is y 
		if(y_addr_s != Y_RAM_SIZE-1'b1)begin //address is not full
			y_addr_s <= y_addr_s + 1'b1;
		end
		else begin
			y_addr_s <= 'b0; //reset y address
		end
	end
	else begin
		y_addr_s <= y_addr_s;
	end
end
//uv address
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		uv_addr_s <= 'b0;
	end
	else if(w_ready&&w_valid&&yuv_flag)begin//input data is uv
		if(uv_addr_s != UV_RAM_SIZE-1'b1)begin //address is not full
			uv_addr_s <= uv_addr_s + 1'b1;
		end
		else begin
			uv_addr_s <= 'b0; //reset uv address
		end
	end
	else begin
		uv_addr_s <= uv_addr_s;
	end
end
//data
//store y data
always @(posedge clk)begin
	if(w_ready&&w_valid&&!yuv_flag)begin //input data is y
		y_ram[y_addr_s] <= data_in;
	end
end
//store uv data
always @(posedge clk)begin 
	if(w_ready&&w_valid&&yuv_flag)begin //input data is uv
		uv_ram[uv_addr_s] <= data_in;
	end
end

//******output logic******
//state
//buffer change
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		buf_num <= 'b0;
	end
	else if(out_complete)begin
		buf_num <= ~buf_num;
	end
	else begin
		buf_num <= buf_num;
	end
end 
//ram flag
assign ram_flag = (r_addr<(Y_CNT-1)||r_addr==7'd95)?1'b0:1'b1;
//out complete
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_complete <= 'b0;
	end
	else if(huv_cnt_o==3'd7&&byte_cnt==2'd2&&macro_cnt == HMACRO_CNT)begin//the last macro block
		out_complete <= 1'b1;
	end
	else begin
		out_complete <= 'b0;
	end
end
//macro count
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		macro_cnt    <= 0;
	end
	else if(huv_cnt_o==3'd7&&byte_cnt==2'd3)begin//the last 4 Bytes of 1 macro block 
		if(macro_cnt == HMACRO_CNT)begin//the last macro block
			macro_cnt <= 'b0;
		end 
		else begin
			macro_cnt <= macro_cnt +1'b1;
		end
	end
	else begin
		macro_cnt <= macro_cnt;
	end
end
//raw control
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		hy_cnt_o  <= 'b0;
		huv_cnt_o <= 'b0;
	end
	else if(buf_valid&&r_ready)begin
		case(ram_flag)
			0:begin //output y
				if(byte_cnt == 2'd3)
					hy_cnt_o <= hy_cnt_o + 1'b1;//y raw add 1
				else
					hy_cnt_o <= hy_cnt_o;
				huv_cnt_o <= huv_cnt_o;
			end
			1:begin //output uv
				if(byte_cnt == 2'd3)
					huv_cnt_o <= huv_cnt_o + 1'b1;
				else
					huv_cnt_o <= huv_cnt_o;
				hy_cnt_o <= hy_cnt_o;
			end
			default:begin
				hy_cnt_o  <= 'b0;
				huv_cnt_o <= 'b0; 
			end
		endcase
	end
	else begin
		hy_cnt_o  <= hy_cnt_o;
		huv_cnt_o <= huv_cnt_o;
	end
end
//output pixels count 1 block  
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		byte_cnt <= 'b0;
	end
	else if(buf_valid&&r_ready)begin
		byte_cnt <= byte_cnt + 1'b1;//number add 1 per time bytes add 4
	end
	else begin
		byte_cnt <= byte_cnt;
	end
end
//change r_addr to real address in ram
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		r_addr <= 'b0;
	end
	else if(buf_valid&&r_ready)begin
		r_addr <= r_addr_i;
	end
	else begin
		r_addr <= r_addr;
	end
end
assign addr_o_r   = (buf_valid&&r_ready)?(r_addr_i<Y_CNT?yaddr_o_r:uvaddr_o_r):'b0;
assign yaddr_o_r  = buf_num*UV_RAM_SIZE + (macro_cnt*16) + hy_cnt_o*(YALL_LENTH+1) + (byte_cnt*4);
assign uvaddr_o_r = buf_num*UV_RAM_SIZE/2 + (macro_cnt*16) + huv_cnt_o*(YALL_LENTH+1) + (byte_cnt*4);
assign y_addr_o   = addr_o_r;
assign uv_addr_o  = addr_o_r[UV_ADDR_WIDTH-1:0];
//data
//output y data
always @(posedge clk)begin
	if(buf_valid&&r_ready&&!ram_flag)begin //output from y ram
		data_y_o = {y_ram[y_addr_o],y_ram[y_addr_o+1'b1],y_ram[y_addr_o+2'd2],y_ram[y_addr_o+2'd3]};
	end
end
//output uv data
always @(posedge clk)begin
	if(buf_valid&&r_ready&&ram_flag)begin //output from uv ram
		data_uv_o = {uv_ram[uv_addr_o],uv_ram[uv_addr_o+1'b1],uv_ram[uv_addr_o+2'd2],uv_ram[uv_addr_o+2'd3]};
	end
end
//output data
assign data_o = r_addr<Y_CNT ? data_y_o : data_uv_o;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		data_valid <= 'b0;
	end
	else if(buf_valid&&r_ready)begin
		data_valid <= 1'b1;
	end
	else begin
		data_valid <= 'b0;
	end
end
//test mode

endmodule