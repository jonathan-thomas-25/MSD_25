module mc_scheduler;

`timescale 1ps/1ps

bit [0:0] cpu_clock;
bit [0:0] dimm_clock;
always #104 cpu_clock=~cpu_clock;
always #208 dimm_clock=~dimm_clock;
bit [0:0] p;
int fh;
int fh1;
bit [0:0] file_done;
string main_q[$:16];
string filename;
string filename1;
longint cpu_clock_count;
longint dimm_clock_count;
string transaction;
string parts[4];
longint clock_cycle_int;
string clock_cycle;
bit [0:0] enable;
string line;
int c;
logic [33:0] address_hex;
logic [1:0] Byte_Select;
logic [3:0] col_low;
logic [5:0] col_high;
logic [9:0] col;
logic [1:0] ba;
logic [2:0] bg;
logic [15:0] row;
bit [0:0] debug_check;
string request_type;
logic channel;
string core;
string address;


always @(posedge cpu_clock)begin

if(file_done==1'b1)begin
if(enable==1'b1)begin
if(!$feof(fh) && $fgets(line,fh))begin                         


$sscanf(line,"%s %s %s %s",parts[0],parts[1],parts[2],parts[3]);

clock_cycle=parts[0];
core=parts[1];
request_type=parts[2];
address=parts[3];
clock_cycle_int=clock_cycle.atoi();
enable=1'b0;

address_hex=address.atohex();
//$display("The address is hex value is %h\n",address_hex);

channel=address_hex[6];
Byte_Select=address_hex[1:0];
col_low=address_hex[5:2];
col_high=address_hex[17:12];
col={col_high,col_low};
ba=address_hex[11:10];
bg=address_hex[9:7];
row=address_hex[33:18];
enable=1'b0;
clock_cycle_int=clock_cycle.atoi();

end

//else $finish;

end
end
end

always @(posedge cpu_clock)begin
cpu_clock_count=cpu_clock_count+1;

if(cpu_clock_count==clock_cycle_int)begin

if(debug_check==1'b1)begin 


if(request_type=="0" || request_type=="2")begin
$display("%0d %s %s  %d  PRE  %d  %d\n",cpu_clock_count,core,request_type,channel,bg,ba);
end

if(request_type=="1")begin
$display("%0d %s %s %d  PRE  %d  %d\n",cpu_clock_count,core,request_type,channel,bg,ba);
end

c=c+1;
if(c>=5)begin
$finish;
end

end//if(debug_check==1'b1)

//$fwrite(fh1,"Item entered in the queue at time %t\n",$time);
main_q.push_back(clock_cycle);
enable=1'b1;

end

end



always @(posedge dimm_clock)begin

if(main_q.size()>0)begin
transaction=main_q.pop_front();

if(debug_check==1'b0)begin

if(request_type=="0" || request_type=="2")begin
$fwrite(fh1,"%d %s %s  %d  PRE  %d  %d\n",cpu_clock_count,core,request_type,channel,bg,ba);
end

if(request_type=="1")begin
$fwrite(fh1,"%d %s %s  %d  PRE  %d  %d\n",cpu_clock_count,core,request_type,channel,bg,ba);
end


end
//$fwrite(fh1,"[TRANSACTION]The current clock cycle is %s and the time is %t\n",transaction,$time);
end

end




initial begin

cpu_clock=1'b0;
dimm_clock=1'b0;
enable=1'b1;
file_done=1'b0;
c=0;

if($value$plusargs("INPUT_FILE=%s", filename))begin

$display("The filename is %s",filename);

end

else filename = "trace.txt";

if($value$plusargs("OUTPUT_FILE=%s", filename1))begin

$display("The filename is %s",filename1);

end

else filename1 = "dram.txt";


fh=$fopen(filename,"r");
if(fh) $display("The trace file %s is successfully opened",filename);
else $display("[ERROR] - Failed to open the trace file");

fh1=$fopen(filename1,"w");


`ifdef DEBUG 
debug_check=1'b1;
`endif
`ifndef DEBUG
debug_check=1'b0;
`endif


file_done=1'b1;


end

endmodule
