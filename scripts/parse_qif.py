#!/usr/bin/env python3

# Prompt: Write a python3 script to read a Quicken Interchange File  and list and total all the transactions within the last month
# e.g.: scripts/parse_qif.py /mnt/c/Users/mlwp/Quicken/Quicken.QIF > transactions.log

import sys
from datetime import datetime, timedelta

def parse_qif_transactions(file_path):
    """
    Parses a QIF file and extracts transactions.
    Filters for transactions within the last 30 days.
    """
    now = datetime.now()
    one_month_ago = now - timedelta(days=30)
    
    transactions = []
    current_tx = {}
    
    # Track overall statistics
    total_amount = 0.0
    matched_count = 0

    print(f"Scanning transactions since: {one_month_ago.strftime('%Y-%m-%d')}\n")
    print(f"{'Date':<12} | {'Amount':<10} | {'Payee/Description'}")
    print("-" * 60)

    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                
                # Header token (e.g., !Type:Bank, !Type:CCard)
                if line.startswith('!'):
                    continue
                
                prefix = line[0]
                value = line[1:]
                
                if prefix == 'D':   # Date field
                    # QIF dates often vary (e.g., "MM/DD/YY", "MM/DD'YY" or "MM/DD/YYYY")
                    # Clean up common Quicken punctuation quirks
                    clean_date = value.replace("'", "/")
                    for fmt in ("%m/%d/%y", "%m/%d/%Y", "%d/%m/%y", "%d/%m/%Y"):
                        try:
                            current_tx['date'] = datetime.strptime(clean_date, fmt)
                            break
                        except ValueError:
                            continue
                elif prefix == 'T': # Amount field
                    # Clean up commas or currency markers if present
                    clean_amount = value.replace(',', '')
                    try:
                        current_tx['amount'] = float(clean_amount)
                    except ValueError:
                        current_tx['amount'] = 0.0
                elif prefix == 'P': # Payee field
                    current_tx['payee'] = value
                elif prefix == '^': # End of record delimiter
                    if 'date' in current_tx and 'amount' in current_tx:
                        tx_date = current_tx['date']
                        tx_amount = current_tx['amount']
                        tx_payee = current_tx.get('payee', 'Unknown Payee')
                        
                        # Filter transactions matching time boundaries
                        if tx_date >= one_month_ago and tx_date <= now:
                            print(f"{tx_date.strftime('%Y-%m-%d'):<12} | {tx_amount:<10.2f} | {tx_payee}")
                            total_amount += tx_amount
                            matched_count += 1
                    
                    # Reset data array for the next record line
                    current_tx = {}
                    
    except FileNotFoundError:
        print(f"Error: The file path '{file_path}' could not be located.")
        sys.exit(1)
        
    print("-" * 60)
    print(f"Total Matched Transactions: {matched_count}")
    print(f"Net Value Change:           ${total_amount:.2f}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 parse_qif.py <path_to_file.qif>")
        sys.exit(1)
        
    parse_qif_transactions(sys.argv[1])
