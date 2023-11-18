module nov17_mc;

`timescale 1ps/1ps

//////////////////////////VARIABLE DECLARATIONS//////////////


//PARSING SIGNALS

string filename;
string filename1;
int fh;
int fh1;
string line;
int c=0;

string clock_cycle;
string core;
string request_type;
string address;
string parts[4];

logic [33:0] address_hex;
logic [1:0] Byte_Select;
logic [3:0] col_low;
logic [5:0] col_high;
logic [9:0] col;
logic [1:0] ba;
logic [2:0] bg;
logic [15:0] row;
logic channel;
int clock_cycle_output;
string command;
int clock_cycle_int;

//HARDWARE SIGNALS
string main_q[$:15];
bit [0:0] cpu_clk;
always #104 cpu_clk=~cpu_clk;
longint cpu_clk_count=0;
bit [0:0] debug_check;
bit [0:0] enable;
//////////////////////ALWAYS LOGIC//////////////////////////

always @(posedge cpu_clk)begin :my_always_block
if(cpu_clk_count==0)begin

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

end

if(!$feof(fh) && $fgets(line,fh))begin


$sscanf(line,"%s %s %s %s",parts[0],parts[1],parts[2],parts[3]);

clock_cycle=parts[0];
core=parts[1];
request_type=parts[2];
address=parts[3];

if(debug_check==1'b1)begin 

$display("###################### TRANSACTIONS ##############################\n");
$display("clock cycle=%s\n",clock_cycle);
$display("core number = %s\n",core);
$display("request type=%s\n",request_type);
$display("address=%s\n",address);

c=c+1;
if(c>=5)begin
break;
end

end

if(debug_check==1'b0)begin

$fwrite(fh1,"###################### TRANSACTIONS ##############################\n");
$fwrite(fh1,"clock cycle=%s\n",clock_cycle);
$fwrite(fh1,"core number = %s\n",core);
$fwrite(fh1,"request type=%s\n",request_type);
$fwrite(fh1,"address=%s\n",address);

end


cpu_clk_count=cpu_clk_count+1;
end //82
//else disable my_always_block;
end
//end
////////////////////////////////////////////////////////////

//////////////////INITIAL BLOCK FOR PARSING/////////////////
initial begin
cpu_clk_count=0;
enable=1'b1;


//$fclose(fh);
//$fclose(fh1);
//#2000 $finish;
end  //line 5

//end


endmodule



