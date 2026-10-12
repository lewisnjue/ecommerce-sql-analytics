| Table | Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `customer` | `customer_id` | `VARCHAR(32)` | Transaction/order-specific customer ID | **NO** | Primary Key |
| | `customer_unique_id` | `VARCHAR(32)` | Unique identifier for the actual customer | **NO** | |
| | `customer_zip_code_prefix` | `VARCHAR(5)` | Postal code prefix | **NO** | |
| | `customer_city` | `VARCHAR(50)` | Customer city name | **NO** | |
| | `customer_state` | `VARCHAR(2)` | 2-letter state code (e.g., SP, RJ) | **NO** | |
| `geolocation` | `id` | `INT GENERATED ALWAYS AS IDENTITY` | Auto-incrementing surrogate key | **NO** | Primary Key |
| | `geolocation_zip_code_prefix` | `VARCHAR(5)` | postal code prefix | NO | |
| | `geolocation_city` | `VARCHAR(50)` | which city | NO | | 
| | `geolocation_lat` | `DOUBLE PRECISION` |  latitude | NO | | 
| | `geolocation_lng` | `DOUBLE PRECISION` | longitude | NO | | 
| | `geolocation_state` | `VARCHAR(2)` | 2 letter state code | NO | |
| `seller` | `seller_id` | `VARCHAR(32)` | sellers unique id  | NO | Primary Key |
| | `seller_zip_code_prefix` | `VARCHAR(5)` | seller code prefix  | NO | | 
| | `seller_city`  | `VARCHAR(50)` | seller city name | NO | | 
| | `seller_state` | `VARCHAR(2)` | seller 2 letter state code | NO | |
| `product`| `product_id` | `VARCHAR(30)` | product unique id | NO | primary key | 
| | `product_category_name` | `VARCHAR(50)` | product category name  | NO | | 
| | `product_name_lenght` | `float64()` | product name lenght ?? | NO | | 
| | `product_description_lenght` | product description lenght | NO | | 
| | `product_photo_qty` | `float64()` | product photo quality | NO | |
| | `product_name`  | `VARCHAR(50)` | name of the product |  NO | |
| | `product_weight_g` | `float64()` | product weight in grams | NO | |
| | `product_length_cm` | `float64()` | product lenght in cm  | NO | |
| | `product_height_cm` | `float64()` | product height in cm | NO | |
| | `product_width_cm` | `float64()` | product width in cm | NO | |
| `product_category_name_translation.` |  `id` | `INT GENERATED ALWAYS AS IDENTITY` | Auto-incrementing surrogate key| *NO** | Primary Key |
| | 
| | `product_category_name` | TEXT | product category name  | NO | |
| | `product_category_name_english` | TEXT | product category name english | NO | |

