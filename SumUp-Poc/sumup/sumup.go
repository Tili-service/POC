package sumup

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

type Transaction struct {
	ID          string  `json:"id"`
	Amount      float64 `json:"amount"`
	Currency    string  `json:"currency"`
	Status      string  `json:"status"`
	Timestamp   string  `json:"timestamp"`
	PaymentType string  `json:"payment_type"`
}

type TransactionsResponse struct {
	Items []Transaction `json:"items"`
}

func GetDayTransactionsetDayTransactions(accessToken string, merchantCode string) ([]Transaction, error) {
	now := time.Now().UTC()
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	endOfDay := startOfDay.Add(24 * time.Hour)

	params := url.Values{}
	params.Set("oldest_time", startOfDay.Format(time.RFC3339))
	params.Set("newest_time", endOfDay.Format(time.RFC3339))
	params.Set("limit", "100")

	fullURL := fmt.Sprintf("https://api.sumup.com/v2.1/merchants/%s/transactions/history?%s", merchantCode, params.Encode())

	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	// fmt.Printf("Transactions API response: %s\n", body)

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API error %d: %s", resp.StatusCode, string(body))
	}

	var result TransactionsResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	return result.Items, nil
}
