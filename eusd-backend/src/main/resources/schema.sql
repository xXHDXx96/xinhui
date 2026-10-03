CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  email VARCHAR(128) UNIQUE NOT NULL,
  phone VARCHAR(20),
  password_hash VARCHAR(256),
  kyc_status VARCHAR(20) DEFAULT 'UNVERIFIED',
  kyc_level VARCHAR(20) DEFAULT 'NONE',
  nickname VARCHAR(64),
  avatar_url VARCHAR(256),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS user_fiat_accounts (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  user_id UUID NOT NULL,
  currency VARCHAR(10) NOT NULL DEFAULT 'CNY',
  balance DECIMAL(18,2) DEFAULT 0.00,
  frozen_balance DECIMAL(18,2) DEFAULT 0.00,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, currency)
);
CREATE TABLE IF NOT EXISTS user_crypto_accounts (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  user_id UUID NOT NULL,
  asset VARCHAR(10) NOT NULL,
  balance DECIMAL(24,8) DEFAULT 0,
  frozen_balance DECIMAL(24,8) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, asset)
);
CREATE TABLE IF NOT EXISTS payment_agreements (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  user_id UUID NOT NULL,
  channel VARCHAR(20) NOT NULL,
  agreement_no VARCHAR(128),
  external_agreement_no VARCHAR(64),
  plan_id VARCHAR(64),
  contract_id VARCHAR(128),
  open_id VARCHAR(128),
  contract_code VARCHAR(64),
  status VARCHAR(30) DEFAULT 'SIGNED',
  signed_at TIMESTAMP,
  terminated_at TIMESTAMP,
  terminated_reason VARCHAR(256),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS recharge_orders (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  user_id UUID NOT NULL,
  channel VARCHAR(20),
  out_trade_no VARCHAR(64) UNIQUE NOT NULL,
  channel_trade_no VARCHAR(128),
  fiat_amount DECIMAL(18,2),
  fiat_currency VARCHAR(10) DEFAULT 'CNY',
  target_asset VARCHAR(10),
  target_amount DECIMAL(24,8),
  exchange_rate DECIMAL(18,8),
  status VARCHAR(20) DEFAULT 'CREATED',
  retry_count INT DEFAULT 0,
  fail_reason VARCHAR(256),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);
CREATE TABLE IF NOT EXISTS exchange_orders (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  user_id UUID NOT NULL,
  from_asset VARCHAR(10),
  to_asset VARCHAR(10),
  from_amount DECIMAL(24,8),
  to_amount DECIMAL(24,8),
  rate DECIMAL(18,8),
  fee DECIMAL(24,8) DEFAULT 0,
  provider VARCHAR(30),
  status VARCHAR(20) DEFAULT 'QUOTED',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);
CREATE TABLE IF NOT EXISTS virtual_cards (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  user_id UUID NOT NULL,
  stripe_card_id VARCHAR(64),
  stripe_cardholder_id VARCHAR(64),
  last4 VARCHAR(4),
  brand VARCHAR(20) DEFAULT 'VISA',
  card_type VARCHAR(20) DEFAULT 'virtual',
  currency VARCHAR(10) DEFAULT 'USD',
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  user_id UUID NOT NULL,
  agreement_id UUID,
  type VARCHAR(30) DEFAULT 'TERMINATION',
  status VARCHAR(20) DEFAULT 'PENDING',
  assigned_admin_id UUID,
  remark TEXT,
  reject_reason VARCHAR(256),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP
);
CREATE TABLE IF NOT EXISTS admins (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  username VARCHAR(64) UNIQUE NOT NULL,
  password_hash VARCHAR(256) NOT NULL,
  role VARCHAR(20) DEFAULT 'SUPPORT',
  status VARCHAR(20) DEFAULT 'ACTIVE',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  user_id UUID NOT NULL,
  type VARCHAR(20) NOT NULL,
  asset VARCHAR(10),
  amount DECIMAL(24,8),
  balance_after DECIMAL(24,8),
  reference_id VARCHAR(128),
  description VARCHAR(256),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 系统配置表（支持后台随时增删改）
CREATE TABLE IF NOT EXISTS system_configs (
  id UUID PRIMARY KEY DEFAULT RANDOM_UUID(),
  config_group VARCHAR(30) NOT NULL,
  config_key VARCHAR(100) NOT NULL,
  config_value VARCHAR(512),
  display_name VARCHAR(100),
  is_secret BOOLEAN DEFAULT FALSE,
  description VARCHAR(256),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(config_group, config_key)
);
