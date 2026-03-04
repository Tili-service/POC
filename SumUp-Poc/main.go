package main

import (
	"SumUp-Poc/sumup"
	"SumUp-Poc/transaction"
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

func initTransactions(apiKey string, merchantCode string) error {
	er := transaction.CreateTransaction(apiKey, 11.00, merchantCode)
	if er != nil {
		return er
	}
	return nil
}

func main() {
	er := godotenv.Load()
	if er != nil {
		fmt.Println("Error loading .env file")
		return
	}
	apiKey := os.Getenv("SUMUP_KEY")
	merchantCode := os.Getenv("SUMUP_MERCHANT_CODE")
	if apiKey == "" {
		fmt.Println("ERROR: API key is empty!")
		return
	}
	if merchantCode == "" {
		fmt.Println("ERROR: Merchant code is empty!")
		return
	}
	// er = initTransactions(apiKey, merchantCode)  - Uncomment to create transactions
	// if er != nil {
	//     fmt.Printf("Error initializing transactions: %v\n", er)
	//     return
	// }
	transactions, err := sumup.GetDayTransactionsetDayTransactions(apiKey, merchantCode)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	fmt.Printf("Today's transactions (%d total):\n", len(transactions))
	total := 0.0
	failed := 0
	for _, tx := range transactions {
		fmt.Printf("- ID: %s | Amount: %.2f %s | Status: %s | Time: %s\n",
			tx.ID, tx.Amount, tx.Currency, tx.Status, tx.Timestamp)
		if tx.Status == "SUCCESSFUL" {
			total += tx.Amount
		} else {
			failed++
		}
	}
	fmt.Printf("Total successful transactions amount: %.2f EUR\n", total)
	if failed > 0 {
		fmt.Printf("Total failed transactions: %d\n", failed)
	}
}
