| Table | Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `customer` | `customer_id` | `VARCHAR(32)` | Transaction/order-specific customer ID | **NO** | Primary Key |
| | `customer_unique_id` | `VARCHAR(32)` | Unique identifier for the actual customer | **NO** | |
| | `customer_zip_code_prefix` | `VARCHAR(5)` | Postal code prefix | **NO** | |
| | `customer_city` | `VARCHAR(40)` | Customer city name | **NO** | |
| | `customer_state` | `VARCHAR(2)` | 2-letter state code (e.g., SP, RJ) | **NO** | |
