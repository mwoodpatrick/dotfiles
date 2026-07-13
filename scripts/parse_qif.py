#!/usr/bin/env python3

# Prompt: Write a python3 script to read a Quicken Interchange File  and list and total all the transactions within the last month include the line number of the transaction in the qif file and sort the transactions by date (ascending)
# e.g.: scripts/parse_qif.py /mnt/c/Users/mlwp/Quicken/Quicken.QIF > transactions.log
# C Cleared Status Cleaned or reconciled status. Blank = unreconciled, * = cleared, X = reconciled
# N Number Check number, reference number, or transaction type (e.g., N1024 or NEFT)
# P Payee The merchant, person, or description line (e.g., PWise London)
# M Memo Any extra notes or descriptions you manually added to the transaction
# L Category / Transfer The assigned Quicken category or the target account name if it's an internal transfer wrapped in brackets (e.g., L[Fidelity Checking])
# Also include the account the transaction comes from
# sort by account and then by date
# Add an option to exclude any transactions where the amount is positive or the  Source Account or payee includes the words "Treasury", "Schwab", "Fidelity", "Balance", " Vanguard ", " Wise" all comparisons should be case insensitive
# Should also exclude transactions where the category is wrapped
# in brackets (e.g., L[Fidelity Checking]) to exclude to exclude  internal account transfers

#!/usr/bin/env python3
import sys
from datetime import datetime, timedelta

def should_exclude(amount, account, payee, category):
    """
    Applies strict filtration constraints. 
    Excludes positive amounts, internal transfers (bracketed categories),
    and matches against a case-insensitive keyword blacklist.
    """
    # Rule 1: Exclude positive amounts (deposits/inflows)
    if amount > 0:
        return True
    
    # Rule 2: Exclude internal account transfers (e.g., L[Fidelity Checking])
    if category.startswith('[') and category.endswith(']'):
        return True
        
    # Rule 3: Substring keyword matching (case-insensitive)
    exclude_keywords = ["treasury", "schwab", "fidelity", "balance", "vanguard", "wise"]
    
    combined_text = (account + payee).lower()
    
    for word in exclude_keywords:
        if word in combined_text:
            return True
            
    return False

def parse_qif_transactions(file_path):
    now = datetime.now()
    one_month_ago = now - timedelta(days=30)
    
    matched_transactions = []
    current_tx = {}
    current_account = "Default"
    in_account_header = False
    line_number = 0
    tx_start_line = 0

    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                line_number += 1
                line = line.strip()
                if not line: continue
                
                if line.startswith('!'):
                    in_account_header = "account" in line.lower()
                    continue
                
                prefix, value = line[0], line[1:]
                
                if in_account_header and prefix == 'N':
                    current_account = value
                    continue

                if not current_tx and prefix in ('D', 'T', 'P', 'C', 'N', 'L'):
                    tx_start_line = line_number

                if prefix == 'D':
                    clean_date = value.replace("'", "/")
                    for fmt in ("%m/%d/%y", "%m/%d/%Y", "%d/%m/%y", "%d/%m/%Y"):
                        try:
                            current_tx['date'] = datetime.strptime(clean_date, fmt)
                            break
                        except ValueError: continue
                elif prefix == 'T':
                    try: current_tx['amount'] = float(value.replace(',', ''))
                    except: current_tx['amount'] = 0.0
                elif prefix == 'C': current_tx['cleared'] = value
                elif prefix == 'N': current_tx['num'] = value
                elif prefix == 'P': current_tx['payee'] = value
                elif prefix == 'L': current_tx['category'] = value
                elif prefix == '^':
                    if 'date' in current_tx and 'amount' in current_tx:
                        cat = current_tx.get('category', '')
                        if one_month_ago <= current_tx['date'] <= now:
                            if not should_exclude(current_tx['amount'], current_account, current_tx.get('payee', ''), cat):
                                current_tx['line_no'] = tx_start_line
                                current_tx['account'] = current_account
                                current_tx['cleared'] = current_tx.get('cleared', '')
                                current_tx['num'] = current_tx.get('num', '-')
                                current_tx['payee'] = current_tx.get('payee', 'Unknown')
                                current_tx['category'] = cat
                                matched_transactions.append(current_tx)
                    current_tx = {}
                    
    except FileNotFoundError:
        sys.exit("Error: File not found.")

    matched_transactions.sort(key=lambda x: (x['account'], x['date']))

    header_fmt = "{:<8} | {:<18} | {:<12} | {:<10} | {:<6} | {:<12} | {:<25} | {:<20}"
    print(header_fmt.format("Line #", "Source Account", "Date", "Amount", "Status", "Ref #", "Payee", "Category"))
    print("-" * 132)

    total = 0.0
    for tx in matched_transactions:
        print(header_fmt.format(tx['line_no'], tx['account'][:18], tx['date'].strftime('%Y-%m-%d'), 
                                f"{tx['amount']:.2f}", tx['cleared'], tx['num'], tx['payee'][:25], tx['category'][:20]))
        total += tx['amount']

    print("-" * 132)
    print(f"Total Transactions: {len(matched_transactions)} | Net Balance Change: ${total:.2f}")

if __name__ == "__main__":
    if len(sys.argv) < 2: sys.exit("Usage: python3 script.py <file.qif>")
    parse_qif_transactions(sys.argv[1])
