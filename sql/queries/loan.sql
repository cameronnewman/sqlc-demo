
-- name: Create :one
INSERT INTO app.loans (
  Loan_ID,
  Artifact_Type,
  Artifact_ID,
  Merchant_ID,
  Payee_ID,
  Payee_Type,
  Number_Of_Repayments,
  Loan_Amount,
  Merchant_Fee,
  Principal,
  Setup_Fee,
  Total_Repayable,
  Status,
  Next_Repayment_Date,
  Origination_Date,
  Maturation_Date
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
  $11, $12, $13, $14, $15, $16
) RETURNING *;