module mc_scheduler;

`timescale 1ps/1ps

//packet description
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
    logic [1:0] request_type;
} Transaction;

typedef enum {INITIAL,PRE,ACT0,ACT1,READ0,READ1,WRITE0,WRITE1,DONE} States;

//Activate delay parameters
parameter tRC=115;
parameter tRRD_l=12;
parameter tRRD_s=8;
parameter tRP=39;
//precharge delay parameters
parameter tRAS=76;
parameter tRTP=18;
parameter tWR=30;
//final state parameters
parameter tCL=40;
parameter tCWD=38;
parameter tBURST=8;
//read/write parameters
parameter tRCD=39;
parameter tCCD_s=8;
parameter tCCD_l=12;
parameter tCCD_l_wr=48;
parameter tCCD_s_wr=8;
parameter tCCD_s_rtw=16;
parameter tCCD_l_rtw=16;
parameter tCCD_s_wtr=52;
parameter tCCD_l_wtr=70;

//Variable declarations
Transaction trans_data;
Transaction end_data;
bit [0:0] enable;
string line;
string filename;
string filename1;
int fh;
int fh1;
bit [0:0] cpu_clock;
bit [0:0] sim_end;
bit [0:0] debug_check;
string act0,act1,rd0,rd1,wr0,wr1,pre;
string request_type;
string core;
string address;
string clock_cycle;
string parts[4];
int bank_number;
longint clock_cycle_int;
longint cpu_clock_count;
longint dimm_clock_count;
longint out_time;
bit [0:0] first_transaction;
Transaction main_q[$:15];

States next_state;
int arg_sent;
string bsr_arguments;
string send_state;
int bk_status;
int time_elapsed;
string bg_row_state;
int line_counter;
int pop_counter;
int first_request;

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
    trans_data.request_type=req_type.atohex();
endfunction

initial begin
   first_transaction=1'b1;
   first_request=0;
   //end_sim_task;
   enable=1'b1;
   cpu_clock=1'b0;
   sim_end=1'b0;
   cpu_clock_count=0;
   dimm_clock_count=0;
   next_state=INITIAL;
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

    while(sim_end!=1'b1)begin
      
      if(enable==1'b1)begin 
       if (!$feof(fh) && $fgets(line, fh)) begin
	 line_counter=line_counter+1;
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

     if(cpu_clock_count>=clock_cycle_int)begin
	if(main_q.size()<15)begin
		main_q.push_back(trans_data);		
		enable=1'b1;
	end
     end

     if(cpu_clock_count%2==0)begin
	dimm_clock_count=dimm_clock_count+1;
		if(main_q.size()>0)begin
		  end_data=main_q[0];
		  bank_number=4*(end_data.bg)+(end_data.ba);
		  out_time=dimm_clock_count*2;

		  case(next_state)
			INITIAL: begin	
					bk_status=bsr("initial",bank_number,end_data.row,end_data.ba,end_data.bg);
					if(bk_status==2)//close page
					begin
						next_state=ACT0;
						void'(bsr("activate",bank_number,end_data.row,end_data.ba,end_data.bg));

					end
					else if (bk_status==3)//page hit
					begin
						if(end_data.request_type==0 |end_data.request_type==2)
						begin
							next_state=READ0;
 							void'(bsr("read",bank_number,end_data.row,end_data.ba,end_data.bg));

						end
						else if(end_data.request_type==1)
						begin
							next_state=WRITE0;
							void'(bsr("write",bank_number,end_data.row,end_data.ba,end_data.bg));

						end
					end
					else if (bk_status==4)//page miss
					begin
							next_state=PRE;
							void'(bsr("precharge",bank_number,end_data.row,end_data.ba,end_data.bg));	
					end
				end
			PRE:begin
					time_elapsed=bsr("precharge",bank_number,end_data.row,end_data.ba,end_data.bg);
					if(time_elapsed)
					begin
						$fwrite(fh1,"%0d %d PRE %d %d\n",out_time,cpu_clock_count,end_data.bg,end_data.ba);
						next_state=ACT0;
						void'(bsr("activate",bank_number,end_data.row,end_data.ba,end_data.bg));
					end 
			    end
						
			ACT0:begin
					//	time_elapsed=bsr("activate",bank_number,end_data.row,end_data.ba,end_data.bg);//MISTAKE here if condition required.					 
						        	
						$fwrite(fh1," %0d %d ACT0 %d %d %h\n",out_time,cpu_clock_count,end_data.bg,end_data.ba,end_data.row);
						$fwrite(fh1," %0d %d ACT1 %d %d %h\n",out_time,cpu_clock_count+2,end_data.bg,end_data.ba,end_data.row);//check clockcycles while writing
						next_state=ACT1;
			
			     end
						
			ACT1:begin
						time_elapsed=bsr("activate",bank_number,end_data.row,end_data.ba,end_data.bg);
						if(time_elapsed && (end_data.request_type==0 || end_data.request_type==1 || end_data.request_type==2))
					begin
						if(end_data.request_type==0 || end_data.request_type==2)
						begin
						next_state=READ0;
						$display("JON1");
					//	send_state="read";
						void'(bsr("read",bank_number,end_data.row,end_data.ba,end_data.bg));
						end
						else if(end_data.request_type==1)
						begin
						next_state=WRITE0;
					//	send_state="write"
						void'(bsr("write",bank_number,end_data.row,end_data.ba,end_data.bg));
						end
					end
		        	end	

						
			READ0:begin
						//time_elapsed=bsr();					
						$fwrite(fh1,"%0d %d READ0 %d %d %h\n",out_time,cpu_clock_count,end_data.bg,end_data.ba,end_data.col);//check clockcycles while writing
						$fwrite(fh1,"%0d %d READ1 %d %d %h\n",out_time,cpu_clock_count+2,end_data.bg,end_data.ba,end_data.col);
						next_state=READ1;	
				end			
			READ1:begin
					time_elapsed=bsr("read",bank_number,end_data.row,end_data.ba,end_data.bg);
					if(time_elapsed)
					begin
						next_state=DONE;
					//	send_state="Done";
						void'(bsr("done",bank_number,end_data.row,end_data.ba,end_data.bg));//done state
					end
				end
			
							
			WRITE0:begin
						$fwrite(fh1,"%0d %d WRITE0 %d %d %h\n",out_time,cpu_clock_count,end_data.bg,end_data.ba,end_data.col);//check clockcycles while writing
						$fwrite(fh1,"%0d %d WRITE1 %d %d %h\n",out_time,cpu_clock_count+2,end_data.bg,end_data.ba,end_data.col);
						next_state=WRITE1;
				end
			WRITE1:begin
					time_elapsed=bsr("write",bank_number,end_data.row,end_data.ba,end_data.bg);
					if(time_elapsed)
					begin
						next_state=DONE;
					//	send_state="Done";
						void'(bsr("done",bank_number,end_data.row,end_data.ba,end_data.bg));
					end

				end
			DONE:begin
					time_elapsed=bsr("initial",bank_number,end_data.row,end_data.ba,end_data.bg);
					if(time_elapsed)
					begin
						$display("timing satisfied for going to in_state");
					void'(bsr("initial",bank_number,end_data.row,end_data.ba,end_data.bg));
						next_state=INITIAL;
						main_q.pop_front();
						pop_counter=pop_counter+1;
					end

				end	
		endcase

		  
		end
     end//dimm_clock

     if($feof(fh)&&(line_counter==pop_counter))begin //&& main_q.size()==0) begin
       sim_end=1'b1;
     end




 
cpu_clock_count=cpu_clock_count+1;		
end//while loop
end//initial 


function int bsr(input string next_state,input int bank_number,input int current_row_value, input int ba, input int bg);
static int bsr_array[31:0][5:0];
//int current_row_value;

parameter BANK_STATUS=0;
parameter PREVIOUS_ROW=1;
parameter PRECHARGE=2;
parameter ACTIVATE=3;
parameter READ=4;
parameter WRITE=5;

int bg_p;
int ba_p;
int bg_a;
int ba_a;
int bg_rd;
int ba_rd;
int bg_wr;
int ba_wr;

int min_activate;
int min_activate_location;
int min_precharge;
int min_precharge_location;
int min_read;
int min_read_location;
int min_write;
int min_write_location;

int delay1;
int delay2;
int delay3;

string stupid_string;
string bg_p_s;
string ba_p_s;
string bg_a_s;
string ba_a_s;
string bg_rd_s;
string ba_rd_s;
string bg_wr_s;
string ba_wr_s;
automatic int i=0;

if(first_request==0)begin
	foreach(bsr_array[i])begin
		foreach(bsr_array[i][j])begin
			bsr_array[i][j]=0;
		end
	end
end

first_request=first_request+1;
//////////////////////////////////////////////////
foreach(bsr_array[i])begin
   foreach(bsr_array[i][j])begin
	if(j>1)begin
	   bsr_array[i][j]=bsr_array[i][j]+1;
	end
   end
end

/////////////////////////////////////////////////
foreach(bsr_array[i])begin
   if(bsr_array[i][PRECHARGE]<min_precharge)begin
	min_precharge=bsr_array[i][PRECHARGE];
	min_precharge_location=i;
   end
end
stupid_string=my_stupid_code(i);
$sscanf(stupid_string,"%0s %0s",bg_p_s,ba_p_s);
bg_p=bg_p_s.atoi();
ba_p=ba_p_s.atoi();
/////////////////////////////////////////////////

foreach(bsr_array[i])begin
   if(bsr_array[i][ACTIVATE]<min_activate)begin
	min_activate=bsr_array[i][ACTIVATE];
	min_activate_location=i;
   end
end
stupid_string=my_stupid_code(i);
$sscanf(stupid_string,"%0s %0s",bg_a_s,ba_a_s);
bg_a=bg_a_s.atoi();
ba_a=ba_a_s.atoi();
/////////////////////////////////////////////////

foreach(bsr_array[i])begin
   if(bsr_array[i][READ]<min_read)begin
	min_read=bsr_array[i][READ];
	min_read_location=i;
   end
end

stupid_string=my_stupid_code(i);
$sscanf(stupid_string,"%0s %0s",bg_rd_s,ba_rd_s);
bg_rd=bg_rd_s.atoi();
ba_rd=ba_rd_s.atoi();
/////////////////////////////////////////////////

foreach(bsr_array[i])begin
   if(bsr_array[i][WRITE]<min_write)begin
	min_write=bsr_array[i][WRITE];
	min_write_location=i;
   end
end

stupid_string=my_stupid_code(i);
$sscanf(stupid_string,"%0s %0s",bg_wr_s,ba_wr_s);
bg_wr=bg_wr_s.atoi();
ba_wr=ba_wr_s.atoi();

/////////////////////////////////////////////////
	

////////////////////////////////////////////////////////////////////////////////////////
//
//			DELAY CALCULATOR
//
////////////////////////////////////////////////////////////////////////////////////////

if(next_state=="initial")begin


	if(bsr_array[bank_number][BANK_STATUS]==1'b0)begin
	   bsr_array[bank_number][PREVIOUS_ROW]=current_row_value;
	 //  bank_status="page_closed";
	   return 2;
	end
	if(bsr_array[bank_number][BANK_STATUS]==1'b1)begin
	   if(current_row_value==bsr_array[bank_number][PREVIOUS_ROW])begin
		bsr_array[bank_number][PREVIOUS_ROW]=current_row_value;
	//	bank_status="page_hit";
		return 3;
	   end	
	   if(current_row_value!=bsr_array[bank_number][PREVIOUS_ROW])begin
		bsr_array[bank_number][PREVIOUS_ROW]=current_row_value;
	//	bank_status="page_miss";
		return 4;
	   end
	end		
end//initial state

if(next_state=="activate")begin
	bsr_array[bank_number][BANK_STATUS]=1'b1;	
	if(bg==bg_a&&ba==ba_a)begin
		delay1=tRC;
	end
	if(bg==bg_a&&ba!=ba_a)begin
		delay1=tRRD_l;
	end
	if(bg!=bg_a)begin
		delay1=tRRD_s;
	end
	if(ba==ba_p)begin
		delay2=tRP;
	end
	else delay2=0;

	if(bsr_array[bg_a*ba_a][ACTIVATE]>delay1 && bsr_array[bg_p*ba_p][PRECHARGE]>delay2)begin //include the same row condition also here
		 bsr_array[bank_number][ACTIVATE]=0;
		 return 1;
	end
end
//endfunction

if(next_state=="precharge")begin

	if(ba!=ba_a)begin
		delay1=tRAS;	
	end

	if(ba==ba_a)begin
		delay1=tRTP;
	end
	
	if(ba==ba_wr)begin 			//include the same row condition also here
		delay2=tBURST+tCWD+tWR;
	end

	if(bsr_array[bg_a*ba_a][ACTIVATE]>delay1 && bsr_array[bg_wr*ba_wr][WRITE]>delay2)begin
		bsr_array[bank_number][PRECHARGE]=0;
		return(1);
	end

end

if(next_state=="read")begin

	if(ba==ba_a)begin                   //include the same row condition also here
		delay1=tRCD;
	end
	if(bg!=bg_wr)begin
		delay2=tCCD_s_wtr;
	end
	if(bg==bg_wr)begin
		delay2=tCCD_l_wtr;
	end
	if(bg!=bg_rd)begin
		delay3=tCCD_s;
	end
	if(bg==bg_rd && ba==ba_rd)begin
		delay3=tCCD_l;
	end
	if(bsr_array[bg_a*ba_a][ACTIVATE]>delay1 && bsr_array[bg_wr*ba_wr][WRITE]>delay2 && bsr_array[bg_rd*ba_rd][READ])begin
		bsr_array[bank_number][READ]=0;
		return(1);
	end
end

if(next_state=="write")begin

	if(ba==ba_a)begin	
		delay1=tRCD;  //include the same row condition here
	end
	if(bg!=bg_rd)begin
		delay2=tCCD_s_rtw;
	end
	if(bg==bg_rd)begin
		delay2=tCCD_l_rtw;
	end
	if(bg==bg_wr && ba!=ba_wr)begin
		delay3=tCCD_l_wr;
	end
	if(bg!=bg_wr)begin
		delay3=tCCD_s_wr;
	end
	
	if(bsr_array[bg_a*ba_a][ACTIVATE]>delay1 && bsr_array[bg_wr*ba_wr][READ]>delay2 && bsr_array[bg_rd*ba_rd][WRITE])begin
		bsr_array[bank_number][WRITE]=0;
		return(1);	
	end
end

if(next_state=="done")begin

	if(min_read<min_write)begin
		delay1=tCL+tBURST;
		if(bsr_array[bg_rd*ba_rd][READ]>delay1)begin
			return(1);
		end
	end
	if(min_read>min_write)begin
		delay1=tCWD+tBURST;
		if(bsr_array[bg_wr*ba_wr][WRITE]>delay1)begin
			return(1);
		end
	end

end

endfunction
	

function string my_stupid_code(input int k);
string s;

if(k==0)begin
s=$sformatf("%d %d",0,0);
return s;
end 

if(k==1)begin
s=$sformatf("%d %d",0,1);
return s;
end

if(k==2)begin
s=$sformatf("%d %d",0,2);
return s;
end

if(k==3)begin
s=$sformatf("%d %d",0,3);
return s;
end

if(k==4)begin
s=$sformatf("%d %d",1,0);
return s;
end

if(k==5)begin
s=$sformatf("%d %d",1,1);
return s;
end

if(k==6)begin
s=$sformatf("%d %d",1,2);
return s;
end

if(k==7)begin
s=$sformatf("%d %d",1,3);
return s;
end

if(k==8)begin
s=$sformatf("%d %d",2,0);
return s;
end

if(k==9)begin
s=$sformatf("%d %d",2,1);
return s;
end

if(k==10)begin
s=$sformatf("%d %d",2,2);
return s;
end

if(k==11)begin
s=$sformatf("%d %d",2,3);
return s;
end

if(k==12)begin
s=$sformatf("%d %d",3,0);
return s;
end

if(k==13)begin
s=$sformatf("%d %d",3,1);
return s;
end

if(k==14)begin
s=$sformatf("%d %d",3,2);
return s;
end

if(k==15)begin
s=$sformatf("%d %d",3,3);
return s;
end

if(k==16)begin
s=$sformatf("%d %d",4,0);
return s;
end

if(k==17)begin
s=$sformatf("%d %d",4,1);
return s;
end

if(k==18)begin
s=$sformatf("%d %d",4,2);
return s;
end

if(k==19)begin
s=$sformatf("%d %d",4,3);
return s;
end

if(k==20)begin
s=$sformatf("%d %d",5,0);
return s;
end

if(k==21)begin
s=$sformatf("%d %d",5,1);
return s;
end

if(k==22)begin
s=$sformatf("%d %d",5,2);
return s;
end

if(k==23)begin
s=$sformatf("%d %d",5,3);
return s;
end

if(k==24)begin
s=$sformatf("%d %d",6,0);
return s;
end

if(k==25)begin
s=$sformatf("%d %d",6,1);
return s;
end

if(k==26)begin
s=$sformatf("%d %d",6,2);
return s;
end

if(k==27)begin
s=$sformatf("%d %d",6,3);
return s;
end

if(k==28)begin
s=$sformatf("%d %d",7,0);
return s;
end

if(k==29)begin
s=$sformatf("%d %d",7,1);
return s;
end

if(k==30)begin
s=$sformatf("%d %d",7,2);
return s;
end

if(k==31)begin
s=$sformatf("%d %d",7,3);
return s;
end

endfunction

endmodule
