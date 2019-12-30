//****************************************
//Filename    : comparer.v
//Author      : MaoRen
//Description : compare two bin file  
//Created     : 2019-12-30
//****************************************
module comparer;

//file name
parameter FILE_A = "four_o.dat";
parameter FILE_B = "four.dat";

//clock 
reg clk;
reg rst_n;

//ram to store file
reg[31:0] ram_a[1<<24:0];
reg[31:0] ram_b[1<<24:0];
//ram address
reg[24:0] addr;
//data register
reg[31:0] data_a;
reg[31:0] data_b;
//logic declaration
//initial clock 
initial begin
	clk = 1'b0;
	forever #5 clk = ~clk;
end

initial begin
	rst_n = 1'b0;
	#10 rst_n = 1'b1;
end

//compare logic
//read data from file 
initial begin
	$readmemh(FILE_A,ram_a);
	$readmemh(FILE_B,ram_b);
end
//compare
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		addr <= 'b0;
	end
	else if(addr != 25'd345600)begin
		addr <= addr + 1'b1;
	end
	else begin
		addr <= addr;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		data_a <= 'b0;
		data_b <= 'b0;
	end
	else begin
		data_a <= ram_a[addr];
		data_b <= ram_b[addr];
	end
end

always@(posedge clk)begin
	if(data_a != data_b)begin
		$display("the different data address is %h",addr);
	end
end

always@(posedge clk)begin
	if(addr == 25'd345600)begin
		#10 $finish;
	end
end

	
endmodule