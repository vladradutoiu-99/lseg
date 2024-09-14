from datetime import timedelta
import pandas as pd

class PandasUtils:
    def __init__(self):
        self.pd = pd

    def get_data_from_file(self, file_path: str, columns: list = None):
        try:
            df = self.pd.read_csv(file_path, names=columns)
            df['TIMESTAMP'] = pd.to_datetime(df['TIMESTAMP'], format='%d-%m-%Y', errors='coerce')
            df.sort_values(by=['TIMESTAMP'], inplace=True)

            return df
        except Exception as e:
            print(f"Error reading file: {e}")
            return None
        
    def get_n_values_from_random_timestamp(self, df: pd.DataFrame, n = 10):
        if df is not None:
            random_timestamp = df['TIMESTAMP'].sample().index[0]

            next_n_rows = df.iloc[random_timestamp:random_timestamp+n]

            next_n_rows['TIMESTAMP'] = next_n_rows['TIMESTAMP'].apply(lambda x: x.strftime('%d-%m-%Y'))

            return next_n_rows
        
        return None
        
    def get_columns(self, df: pd.DataFrame):
        return df.columns.tolist()
    
    def get_stock_df_from_list(self, data: list):
        df = self.pd.DataFrame(data)
        df['TIMESTAMP'] = pd.to_datetime(df['TIMESTAMP'], format='%d-%m-%Y', errors='coerce')

        return df
    
    def predict_rows_in_df(self, df: pd.DataFrame):
        second_highest_price = sorted(df['PRICE'])[-2]

        print(f"Second highest price: {second_highest_price}")

        last_price = df['PRICE'].iloc[-1]
        second_predicted = second_highest_price +  (last_price - second_highest_price) / 2
        third_predicted = second_predicted - (second_predicted - last_price) / 4


        new_dates = [df['TIMESTAMP'].max() + timedelta(days=i) for i in range(1, 4)]

        new_data = [
            {"STOCK_ID": df['STOCK_ID'][0], "TIMESTAMP": new_dates[0], "PRICE": second_highest_price},
            {"STOCK_ID": df['STOCK_ID'][0], "TIMESTAMP": new_dates[1], "PRICE": second_predicted},
            {"STOCK_ID": df['STOCK_ID'][0], "TIMESTAMP": new_dates[2], "PRICE": third_predicted}
        ]

        predicted_df = pd.DataFrame(new_data)
        result_df = pd.concat([df, predicted_df], ignore_index=True)

        result_df['TIMESTAMP'] = result_df['TIMESTAMP'].apply(lambda x: x.strftime('%d-%m-%Y'))

        return result_df