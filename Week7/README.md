# Pandas Data Exploration & Cleaning

A hands-on project exploring, cleaning, and preparing a retail sales dataset using Pandas — covering everything from handling missing values to duplicate removal and feature engineering.

## 📊 Dataset

I used a locally generated CSV (`superstore_sample.csv`, 310 rows, 15 columns) built to match the structure of the [Kaggle Superstore dataset](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final) — think Order ID, Category, Region, Price, Quantity, etc.

Kaggle requires an API key to pull files directly, which wasn't available in this environment, so I generated a stand-in dataset with the same kinds of messiness (missing values, duplicates) you'd actually run into with the real file. The notebook itself needs **zero changes** to work on the real Kaggle CSV — just swap the filename in Step 1 and you're good to go.

## 🛠️ What I did

1. **Loaded the data** with `pd.read_csv()`.
2. **Poked around** using `head()`, `tail()`, `shape`, `columns`, `dtypes`, `info()`, and `describe()` to get a feel for what I was working with.
3. **Cleaned up missing values** — found 36 empty cells scattered across `Price`, `Quantity`, `Region`, and `Ship Mode`. Filled the numeric gaps with the median, the categorical gaps with the mode, and demonstrated how `dropna()` works on a critical identifier column, for cases where you'd rather drop a row than guess at it.
4. **Filtered and sliced the data** — pulled out things like Technology orders over $100, bulk orders with quantity ≥ 5, and narrowed columns down to just `Order ID`, `Category`, `Price`, and `Quantity` when that's all I needed.
5. **Killed the duplicates** — found 10 rows that were exact copies and dropped them.
6. **Added a new column**, `total_amount` (Price × Quantity), so the data's ready for revenue-style analysis.
7. **Exported the result** to `superstore_cleaned.csv`.

## ✅ Result

| Metric | Value |
|---|---|
| Final shape | 300 rows × 16 columns |
| Missing values | 0 |
| Duplicate rows | 0 |
| New columns added | `total_amount` |

## 📁 Repo contents

```
.
├── data_cleaning_pandas.ipynb   # Full notebook: code, explanations, outputs
├── superstore_sample.csv        # Raw input data
├── superstore_cleaned.csv       # Cleaned output data
└── README.md                    # This file
```

## 🚀 Getting started

```bash
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
pip install pandas jupyter
jupyter notebook data_cleaning_pandas.ipynb
```

To run against the real Kaggle dataset instead of the sample, download it from [Kaggle](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final), place it in the repo folder, and update the filename in **Step 1** of the notebook.

## 🧰 Tools used

- Python
- Pandas
- Jupyter Notebook

## 📝 License

Feel free to use, modify, and share this project. Attribution appreciated but not required.
