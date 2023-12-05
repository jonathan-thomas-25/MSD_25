import random

'''def random_binary(start_bin, stop_bin):
    # Convert binary strings to integers
    start_int =int(start_bin)
    stop_int = int(stop_bin)
    
    # Generate a random binary value within the specified range
    random_value = random.randrange(start_int, stop_int + 1)
    
    # Convert the result back to binary representation
    return bin(random_value)[2:]'''
'''
with open('dhruva.txt','w') as f:
    f.write('why man')
    '''
# Example usage:11
time_input = int(input("Enter time: "))
op = int(input("Enter Operation: "))
bankgroup = int(input("Enter bank group: "))
bank = int(input("Enter bank: "))
row = int(input("Enter row: ")) 

def generate_trace_file( time, operation, bankgroup, bank, row):
    # Convert decimal numbers to hexadecimal
    time_con = time
    core = random.randint(0,11)
    operation_con = operation
    bankgroup_bin = bin(bankgroup)[2:]
    bank_bin = bin(bank)[2:]
    row_bin = bin(row)[2:]
    column_bin1 = random.randint(0b0000, 0b1111)
    column_bin2 = random.randint(0b000000, 0b111111)
    Byteselect = random.randint(0b00, 0b11)
    address = [34]
    address[0:1] = bin(Byteselect)[2:]
    address[2:5] = bin(column_bin1)[2:]
    address[6] = 0
    address[7:9] = bankgroup_bin
    address[10:11] = bank_bin
    address[12:17] = bin(column_bin2)[2:]
    address[18:33] = row_bin

    hex_address = ''.join(format(element, '02X') for element in address)

    #file_path = r'D:\trace_file.txt'
    
    # Format the data for the trace file  
    trace_data = f"{time_con} {core} {operation_con} {hex_address}\n"
    # Write the formatted data to the trace file
    with open('trace_file.txt','w') as trace_file:
            trace_file.write(trace_data)
    


generate_trace_file(time_input,op,bankgroup,bank,row)

