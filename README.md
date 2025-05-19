# Validator Startup Script with HashiCorp Vault Integration

This script is designed to securely start a Solana validator by dynamically fetching the validator's private key from a HashiCorp Vault instance. The identity file is kept in memory using a temporary file, enhancing security and minimizing the risk of private key exposure on disk.

## Features

- **HashiCorp Vault Integration**: Securely fetches the validator's private key at runtime.
- **In-Memory Key Handling**: Uses `tmpfs` (`/dev/shm`) to hold sensitive identity data in memory.
- **Symbolic Linking**: Maintains a standard path (`/home/sol/id.json`) for the identity file.

---

## Environment Setup

Ensure the following prerequisites are met:

1. HashiCorp Vault is accessible and contains a secret with a `PRIVATE_KEY` field.
2. `/home/sol/.env.prod` exists with the line:
   ```bash
   VAULT_TOKEN=<your-vault-token>
   ```

## Vault Secret Format

The secret stored in HashiCorp Vault should be structured as follows:

```json
{
	"PUBLIC_KEY": "asdfasfd",
	"PRIVATE_KEY": [
		/* array of private key bytes */
	]
}
```

- The script extracts the `PRIVATE_KEY` field and serializes it into JSON format to create a valid identity file used by the validator.
- Ensure the `PRIVATE_KEY` is a properly ordered array of bytes matching the Solana keypair format.

## 🤝 Contributing

We welcome contributions from the community! To get started:

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a pull request

---

## 📝 License

This project is licensed under the [Apache 2.0 License](LICENSE).

---

## 👨‍💻 Author

Built and maintained by the Brew Labs team.
