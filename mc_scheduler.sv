module mc_scheduler;



initial begin

//////////////////////////VARIABLE DECLARATIONS//////////////

string filename;
string filename1;
int fh;
int fh1;
string line;


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




////////////////////////////////////////////////////////////


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


while(!$feof(fh))begin
$fgets(line,fh);
//line.split(" ",parts);

$sscanf(line,"%s %s %s %s",parts[0],parts[1],parts[2],parts[3]);

clock_cycle=parts[0];
core=parts[1];
request_type=parts[2];
address=parts[3];

address_hex=address.atohex();
clock_cycle_output=$urandom_range(50,100);
//$display("The address is hex value is %h\n",address_hex);

channel=address_hex[6];
Byte_Select=address_hex[1:0];
col_low=address_hex[5:2];
col_high=address_hex[17:12];
col={col_high,col_low};
ba=address_hex[11:10];
bg=address_hex[9:7];
row=address_hex[33:18];

/////////////////////DEBUG CODE//////////////////////////
`ifdef DEBUG 

$fwrite(fh1,"###################### TRANSACTIONS ##############################\n");
$fwrite(fh1,"clock cycle=%s\n",clock_cycle);
$fwrite(fh1,"core number = %s\n",core);
$fwrite(fh1,"request type=%s\n",request_type);
$fwrite(fh1,"address=%s\n",address);

//if(request_type=="0" || request_type=="2")begin
//$fwrite(fh1,"100  %d  PRE  %d  %d\n",channel,bg,ba);
//$fwrite(fh1,"120  %d  ACT  %d  %d  %h\n",channel,bg,ba,row);
//$fwrite(fh1, "128 %d  RD   %d  %d  %h\n",channel,bg,ba,col);
//end

//if(request_type=="1")begin
//$fwrite(fh1,"100  %d  PRE  %d  %d\n",channel,bg,ba);
//$fwrite(fh1,"120  %d  ACT  %d  %d  %h\n",channel,bg,ba,row);
//$fwrite(fh1, "128 %d  RD   %d  %d  %h\n",channel,bg,ba,col);
//end

end



`endif
end
//$fclose(fh);
//$fclose(fh1);
////////////////////////////////////////////////////////////


//end


endmodule 
