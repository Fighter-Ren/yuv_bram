## RAM : 用于改变摄像头输入数据YUV420的存储方式以便其能通过视频编码器编码

### 设计要点

**1、摄像头输出数据方式为YUYV.../YYYY...** 

**2、一个buffer存储16行视频数据，UV为8行，每行数据为图片长度**

**3、使用双buffer模式，可同时读写，但不可对同一buffer读写**

### 文件说明：

**yuv2ram.m   : 将正常顺序yuv视频文件转换成摄像头输出顺序存储**

**yuv_ram.v   : 实现ram存储视频数据并将其按编码器读取顺序输出**

**top_tb.v    : testbench文件，用于测试yuv_ram的功能正确性**

**addr_test.v : 用于模拟编码器读取视频数据的时序**

**comparer.v  : 比较输出的数据是否和真实数据顺序相同(宏块存储)**

**four.dat    : 真实数据**

**four_o.dat  : 输出数据**

**four_b.dat  : 输入数据**