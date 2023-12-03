import random

def generate_large_trace_file(file_path="trace.txt", num_entries=100000):
    with open(file_path, 'w') as file:
        for i in range(num_entries):
            time = i 
            core = random.randint(0, 11)
            
            operation = i % 3

            # Random Address
            address_base = random.randint(0x300000000, 0x3FFFFFFFF)   
            
            # Byte Alignment
            if i % 2 == 0:
                address = hex(address_base & ~0xF | 0x0)[2:].zfill(9)
            else:
                address = hex(address_base & ~0xF | 0x8)[2:].zfill(9)

            line = f"{time} {core} {operation}   {address}\n"
            file.write(line)

    print(f"Trace file '{file_path}' with {num_entries} entries generated successfully.")

def main():
    file_path = input("Enter the trace file name (default is trace.txt): ").strip() or "trace.txt"

    try:
        num_entries = int(input("Enter the number of entries (default is 100000): ").strip() or "100000")
    except ValueError:
        print("Invalid input for the number of entries. Using the default value of 100000.")
        num_entries = 100000

    generate_large_trace_file(file_path, num_entries)

if __name__ == "__main__":
    main()

