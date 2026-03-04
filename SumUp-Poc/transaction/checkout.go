package transaction

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

func processTestCheckout(apiKey string, checkoutID string) error {
	payload := map[string]interface{}{
		"payment_type": "card",
		"card": map[string]interface{}{
			"name":         "Test User",
			"number":       "4111111111111111",
			"expiry_month": "12",
			"expiry_year":  "2026",
			"cvv":          "123",
		},
	}

	body, _ := json.Marshal(payload)

	url := fmt.Sprintf("https://api.sumup.com/v0.1/checkouts/%s", checkoutID)
	req, err := http.NewRequest("PUT", url, bytes.NewBuffer(body))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// respBody, _ := io.ReadAll(resp.Body) - Uncomment if you want to see the response from processing the checkout
	// fmt.Printf("Processed checkout: %s\n", respBody)
	return nil
}

func CreateTransaction(accessToken string, amount float64, merchantCode string) error {
	payload := map[string]interface{}{
		"checkout_reference": fmt.Sprintf("test-%d", time.Now().UnixNano()),
		"amount":             amount,
		"currency":           "EUR",
		"merchant_code":      merchantCode,
		"description":        "Test transaction",
	}

	body, _ := json.Marshal(payload)

	req, err := http.NewRequest("POST", "https://api.sumup.com/v0.1/checkouts", bytes.NewBuffer(body))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)

	var checkoutResp map[string]interface{}
	if err := json.Unmarshal(respBody, &checkoutResp); err != nil {
		return fmt.Errorf("failed to parse checkout response: %w", err)
	}
	checkoutID, ok := checkoutResp["id"].(string)
	if !ok || checkoutID == "" {
		return fmt.Errorf("checkout ID missing from response: %s", respBody)
	}

	time.Sleep(1 * time.Second)
	return processTestCheckout(accessToken, checkoutID)
}
