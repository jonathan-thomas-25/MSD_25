
import random



def generate_trace_file(time, operation, bankgroup, bank, row):
    # Convert decimal numbers to hexadecimal
    time_con = time
    core = random.randint(0, 11)
    operation_con = operation
    bankgroup_bin = format(bankgroup, '03b')
    bank_bin = format(bank, '02b')
    row_bin = format(row, '016b')
    column_bin1 = format(random.randint(0b0000, 0b1111), '04b')
    column_bin2 = format(random.randint(0b000000, 0b111111), '06b')
    Byteselect = format(random.randint(0b00, 0b11), '02b')

    address = [
        *row_bin,
        *column_bin2,
        *bank_bin,
        *bankgroup_bin,
        '0',
        *column_bin1,
        *Byteselect
    ]

    hex_address = hex(int(''.join(map(str, address)), 2))[2:].zfill(9)

    # file_path = r'D:\trace_file.txt'

    # Format the data for the trace file
    trace_data = f"{time_con} {core} {operation_con} {hex_address}\n"
    # Write the formatted data to the trace file
    with open('trace_file.txt', 'a') as trace_file:
        trace_file.write(trace_data)

z = int(input("Enter number of entries: "))
y = int(input("To clear previous traces[enter 1] & To add to previous traces [enter 0]: "))

    # To clear inputs
if(y==1):
    with open('trace_file.txt', 'w'):
        pass


for _ in range(z):
    time_input = int(input("Enter time: "))
    op = int(input("Enter Operation: "))
    bankgroup = int(input("Enter bank group: "))
    bank = int(input("Enter bank: "))
    row = int(input("Enter row: "))
    generate_trace_file(time_input, op, bankgroup, bank, row)

