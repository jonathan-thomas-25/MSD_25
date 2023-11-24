module mc_scheduler;

typedef struct {
    logic [33:0] address_hex;
    logic [1:0] Byte_Select;
    logic [3:0] col_low;
    logic [5:0] col_high;
    logic [9:0] col;
    logic [1:0] ba;
    logic [2:0] bg;
    logic [15:0] row;
    logic [0:0] channel;
} Transaction;

`timescale 1ps/1ps
Transaction trans_data;
bit [0:0] enable;
string clock_cycle;
string parts[4];
string line;
string filename;
string filename1;
int fh;
int fh1;
string request_type;
string core;
string address;

bit [0:0] cpu_clock;
bit [0:0] sim_end;
bit [0:0] debug_check;
string main_q [$:15]; 
longint cpu_clock_count;
longint dimm_clock_count;
longint clock_cycle_int;
longint out_time;
longint dimm_clock_temp;
string transaction_in;
string transaction_out;

function void parse_transaction(string clock, string core, string req_type, string addr);
    trans_data.address_hex = addr.atohex();
    trans_data.channel = trans_data.address_hex[6];
    trans_data.Byte_Select = trans_data.address_hex[1:0];
    trans_data.col_low = trans_data.address_hex[5:2];
    trans_data.col_high = trans_data.address_hex[17:12];
    trans_data.col = {trans_data.col_high, trans_data.col_low};
    trans_data.ba = trans_data.address_hex[11:10];
    trans_data.bg = trans_data.address_hex[9:7];
    trans_data.row = trans_data.address_hex[33:18];
endfunction
task end_sim_task;
if($feof(fh) && sim_end) begin
	$finish;
end
endtask

initial begin
end_sim_task;
   enable=1'b1;
   cpu_clock=1'b0;
   sim_end=1'b0;
   cpu_clock_count=0;
   dimm_clock_count=0;
   dimm_clock_temp=0;
   if ($value$plusargs("INPUT_FILE=%s", filename)) begin
      $display("The filename is %s", filename);
   end
   else filename = "trace.txt";

   if ($value$plusargs("OUTPUT_FILE=%s", filename1)) begin
        $display("The filename is %s", filename1);
   end
   else filename1 = "dram.txt";

   fh = $fopen(filename, "r");
   if (fh) $display("The trace file %s is successfully opened", filename);
   else $display("[ERROR] - Failed to open the trace file");

   fh1 = $fopen(filename1, "w");

   `ifdef DEBUG
       debug_check = 1'b1;
   `endif
   `ifndef DEBUG
       debug_check = 1'b0;
    `endif
 //  forever #104 cpu_clock=~cpu_clock;
   while(sim_end!=1'b1)begin
     if(enable==1'b1)begin 
      if (!$feof(fh) && $fgets(line, fh)) begin                        
        $sscanf(line, "%s %s %s %s", parts[0], parts[1], parts[2], parts[3]);
        clock_cycle = parts[0];
        core = parts[1];
        request_type = parts[2];
        address = parts[3];
        clock_cycle_int = clock_cycle.atoi();
        enable = 1'b0;
        parse_transaction(clock_cycle, core, request_type, address); 
	clock_cycle_int=clock_cycle.atoi();       
      end
     end	
      if(cpu_clock_count!=0)begin
        if(cpu_clock_count%2==0)begin	
      	  dimm_clock_count=dimm_clock_count+1;
        end
      end
 
      if(cpu_clock_count>=clock_cycle_int)begin
	if (request_type == "0" || request_type == "2") begin
	   transaction_in=$sformatf("ACT0 %0h %0h %0h\nACT1 %0h %0h %0h\nRD0 %0h\nPRE %0h %0h \n",trans_data.bg,trans_data.ba,trans_data.row,trans_data.bg,trans_data.ba,trans_data.row,trans_data.col,trans_data.bg,trans_data.ba);
	end
        if (request_type == "1") begin
	   transaction_in=$sformatf("ACT0 %0h %0h %0h\nACT1 %0h %0h %0h\nWR0 %0h\nPRE %0h %0h \n",trans_data.bg,trans_data.ba,trans_data.row,trans_data.bg,trans_data.ba,trans_data.row,trans_data.col,trans_data.bg,trans_data.ba);
	end
	if(main_q.size()<15)begin	
           main_q.push_back(transaction_in);
	   enable=1'b1;
	end
      end// cpu_clock_cycle>=clock_cycle_int
 
      if(dimm_clock_temp!=dimm_clock_count)begin
	dimm_clock_temp=dimm_clock_count;
	if(main_q.size()>0)begin
	transaction_out = main_q.pop_front();
	out_time=dimm_clock_count*2;
	if (debug_check == 1'b0) begin
	    
            if (request_type == "0" || request_type == "2") begin
	        //foreach(main_q[i]) $fwrite(fh1,"%s\n",main_q[i]);
		$fwrite(fh1,"###############CPU Time Elapsed -------%0d  ###################\n",out_time);
                $fwrite(fh1,"%s\n" ,out_time,transaction_out);
		$fwrite(fh1,"The number of elements in the queue is %d\n",main_q.size());
		//$fwrite(fh1,"The FULL ADDRESS IS %s\n",address);
		$fwrite(fh1,"#############################################################\n\n");
            end

            if (request_type == "1") begin
		$fwrite(fh1,"###############CPU Time Elapsed -------%0d ###################\n",out_time);
                $fwrite(fh1,"%s\n",out_time,transaction_out);
		$fwrite(fh1,"The number of elements in the queue is %d\n",main_q.size());
		//$fwrite(fh1,"The FULL ADDRESS IS %s\n",address);
		$fwrite(fh1,"#############################################################\n\n");
            end
        end//debug_check==1'b0

	else begin
	   
	   if (request_type == "0" || request_type == "2") begin
		$display("CPU Time Elapsed -------%0d\n",out_time);
                $display("%0d %s\n" ,out_time,transaction_out);
            end

            if (request_type == "1") begin
		$display("CPU Time Elapsed -------%0d\n",out_time);
                $display("%0d %s\n",out_time,transaction_out);
       	    end
	end

	if($feof(fh)) begin
        sim_end=1'b1;
	end

      end//dimm clock block
		
    end
	cpu_clock_count=cpu_clock_count+1;
end//while
end//initial
endmodule
