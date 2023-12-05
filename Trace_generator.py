
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
    return trace_data

def process_input_file(input_file_path, output_file_path):
    with open(input_file_path, 'r') as input_file:
        lines = input_file.readlines()

    with open(output_file_path, 'w') as output_file:
        for line in lines:
            if not line.strip():
                continue  # Skip empty lines
            # Assuming each line contains space-separated values for time, operation, bankgroup, bank, and row
            time_input, op, bankgroup, bank, row = map(int, line.split())
            trace_data = generate_trace_file(time_input, op, bankgroup, bank, row)
            output_file.write(trace_data)

def main():
    input_file_path = r"C:\\Users\\dhruv\\newpy\\input.txt"  
    output_file_path = r"C:\\Users\\dhruv\\newpy\\output.txt" 
    
    process_input_file(input_file_path, output_file_path)
    print(f"Trace data generated and saved to {output_file_path}")

if __name__ == "__main__":
    main() 
