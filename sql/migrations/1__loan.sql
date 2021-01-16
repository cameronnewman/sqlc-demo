-- +migrate Up
CREATE TYPE Loan_Status AS ENUM (
  'Approved', 
  'Active', 
  'Complete', 
  'Paused',
  'Collections', 
  'WrittenOff',
  'Voided'
);

CREATE TYPE Payee_Type AS ENUM (
  'User', 
  'Business'
);

CREATE TYPE Artifact_Type AS ENUM (
  'Invoice', 
  'PaymentLink'
);


CREATE TABLE IF NOT EXISTS app.loans (
    Loan_ID UUID PRIMARY KEY,
    Artifact_Type Artifact_Type NOT NULL,
    Artifact_ID  UUID NOT NULL,
    Merchant_ID UUID NOT NULL,
    Payee_ID  UUID NOT NULL,
    Payee_Type Payee_Type NOT NULL,
    Number_Of_Repayments int NOT NULL,
    Loan_Amount NUMERIC NOT NULL, 
    Merchant_Fee NUMERIC NOT NULL,
    Principal NUMERIC NOT NULL,
    Setup_Fee NUMERIC NOT NULL DEFAULT 0,
    Total_Repayable NUMERIC NOT NULL,
    Status Loan_Status  NOT NULL,
    Next_Repayment_Date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    Origination_Date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    Maturation_Date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
