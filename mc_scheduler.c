#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void main(int argc,char* argv[]){

///////////////////////////////////VARIABLE DECLARATIONS////////////////////////////////
FILE* file;
char input_file[];
char data[50];

////////////////////////////////////////////////////////////////////////////////////////
input_file=argv[1];
file=fopen(input_file,"r");

if(file==NULL){
perror("[ERROR] The Trace file is empty")    ; //tell me why
return(1);
}

else {

while(fgets(data,50,file)!=NULL){

printf("%s\n", data);

}
}
fclose(file);

}



