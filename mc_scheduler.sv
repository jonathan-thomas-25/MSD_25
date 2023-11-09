module mc_scheduler;



initial begin

//////////////////////////VARIABLE DECLARATIONS//////////////

string filename;
int fh;
string line;
string clock_cycle;
string core;
string request_type;
string address;
string parts[4];
////////////////////////////////////////////////////////////


if($value$plusargs("MYFILE=%s", filename))begin

$display("The filename is %s",filename);

end

else filename = "trace.txt";

fh=$fopen(filename,"r");
if(fh) $display("The trace file %s is successfully opened",filename);
else $display("[ERROR] - Failed to open the trace file");


for(int i=0;i<5;i++)begin
$fgets(line,fh);
//line.split(" ",parts);

$sscanf(line,"%s %s %s %s",parts[0],parts[1],parts[2],parts[3]);

clock_cycle=parts[0];
core=parts[1];
request_type=parts[2];
address=parts[3];

/////////////////////DEBUG CODE//////////////////////////
`ifdef DEBUG 

$display("###################### TRANSACTIONS ##############################");
$display("clock cycle=%s",clock_cycle);
$display("core number = %s",core);
$display("request type=%s",request_type);
$display("address=%s",address);

`endif


end	


////////////////////////////////////////////////////////////





end




endmodule 
