# 🕰️ ChronoVault

**Advanced Time-Locked Digital Asset Vault with Integrated Yield Generation**

ChronoVault is a sophisticated Clarity smart contract that provides secure, time-locked storage for digital assets on the Stacks blockchain, featuring multi-signature authorization, heir designation, and built-in DeFi yield farming capabilities.

## 🚀 Key Features

### 🔒 **Time-Locked Security**
- **Configurable Lock Periods**: Set custom timelock durations for enhanced security
- **Multi-Guardian Authorization**: Require multiple trusted guardians to sign off on withdrawals
- **Emergency Heir Access**: Designated beneficiaries can access funds after extended timelock expiry

### 💰 **Integrated Yield Generation**
- **Passive Income Earning**: Stake deposited assets to earn yield while they're locked
- **Flexible Staking**: Start and stop yield farming positions at any time
- **Compound Growth**: Harvest rewards regularly or let them compound automatically
- **Adjustable APY**: Vault owners can modify yield rates based on market conditions

### 🛡️ **Advanced Security Features**
- **Multi-Signature Controls**: Configurable guardian threshold system
- **Owner Access Controls**: Comprehensive permission management
- **Emergency Protocols**: Heir-based recovery mechanisms
- **Withdrawal Round System**: Organized authorization processes

## 📋 Contract Functions

### Vault Management
- `configure-chronovault()` - Initialize vault with timelock and guardian settings
- `deposit-assets()` - Add STX to the vault
- `execute-withdrawal()` - Withdraw funds (requires proper authorization)
- `transfer-vault-ownership()` - Change vault ownership

### Guardian System
- `register-guardian()` - Add trusted guardians
- `remove-guardian()` - Remove guardian access
- `provide-guardian-signature()` - Sign withdrawal authorizations
- `begin-withdrawal-round()` - Start new authorization cycle

### Yield Farming
- `initiate-yield-staking()` - Begin earning yield on deposited assets
- `harvest-yield-rewards()` - Claim accumulated rewards
- `complete-yield-staking()` - End staking and withdraw principal + rewards
- `adjust-yield-rate()` - Modify annual yield percentage

### Information Queries
- `get-timelock-expiry()` - Check when timelock expires
- `get-total-vault-balance()` - View total assets in vault
- `get-user-yield-stake()` - Check active staking position
- `get-cumulative-yield-generated()` - View total yield earned

## 🔧 Usage Examples

### Basic Vault Setup
```clarity
;; Configure vault with 1-year timelock, requiring 3 guardian signatures
(configure-chronovault u52560 u3 (some 'SP2HEIR123...))

;; Add trusted guardians
(register-guardian 'SP2GUARDIAN1...)
(register-guardian 'SP2GUARDIAN2...)  
(register-guardian 'SP2GUARDIAN3...)

;; Deposit 1000 STX
(deposit-assets u1000000000) ;; 1000 STX in microSTX
```

### Yield Farming
```clarity
;; Start earning yield on 500 STX
(initiate-yield-staking u500000000)

;; Harvest rewards after some time
(harvest-yield-rewards)

;; Complete staking and withdraw everything
(complete-yield-staking)
```

### Withdrawal Process
```clarity
;; Owner initiates withdrawal round
(begin-withdrawal-round)

;; Guardians provide signatures
(provide-guardian-signature) ;; Called by each guardian

;; Execute withdrawal once timelock expires and signatures collected
(execute-withdrawal u100000000) ;; Withdraw 100 STX
```

## 🏗️ Technical Architecture

### Data Storage
- **State Variables**: Core vault configuration and status
- **Mappings**: Guardian permissions, signatures, and yield positions
- **Error Handling**: Comprehensive error codes for all failure scenarios

### Security Model
- **Time-based Access**: Funds locked until specified block height
- **Multi-signature Authorization**: Configurable threshold system
- **Inheritance Protocol**: Designated heir emergency access
- **Permission Controls**: Owner-only administrative functions

### Yield Mechanism
- **Block-based Calculation**: Yield computed using block height differences
- **Compound Interest**: Optional reward harvesting for compounding
- **Rate Flexibility**: Owner-adjustable annual percentage yield
- **Position Tracking**: Individual stake monitoring and management

## ⚠️ Security Considerations

1. **Guardian Selection**: Choose trusted, reliable guardians who can coordinate signatures
2. **Timelock Duration**: Balance security needs with accessibility requirements
3. **Heir Designation**: Ensure heir address is secure and accessible long-term
4. **Yield Rate Management**: Monitor and adjust rates based on market conditions
5. **Key Management**: Secure storage of owner and guardian private keys

## 📊 Error Codes Reference

| Code | Error | Description |
|------|-------|-------------|
| 100 | `ERR-UNAUTHORIZED-ACCESS` | Caller lacks required permissions |
| 101 | `ERR-VAULT-ALREADY-CONFIGURED` | Vault has already been initialized |
| 102 | `ERR-VAULT-NOT-CONFIGURED` | Vault must be configured first |
| 103 | `ERR-TIMELOCK-STILL-ACTIVE` | Cannot withdraw while timelock active |
| 104 | `ERR-INSUFFICIENT-GUARDIAN-SIGNATURES` | Need more guardian approvals |
| 105 | `ERR-INVALID-HEIR-ADDRESS` | Heir address validation failed |
| 112 | `ERR-YIELD-POSITION-EXISTS` | User already has active yield position |
| 113 | `ERR-NO-ACTIVE-YIELD-POSITION` | No yield farming position found |
| 114 | `ERR-INSUFFICIENT-VAULT-BALANCE` | Not enough funds in vault |

## 🔮 Future Enhancements

- **Multi-Token Support**: Extend beyond STX to other Stacks tokens
- **Dynamic Yield Rates**: Market-responsive yield adjustments
- **Governance Integration**: Community-driven parameter updates
- **Insurance Integration**: Optional asset protection mechanisms
- **Mobile Interface**: User-friendly mobile application

## 📜 License

This project is released under the MIT License. See LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

---

**⚡ ChronoVault - Securing Digital Assets Across Time ⚡**
