import pandas as pd
import os
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestRegressor
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder

class VyaparSetuPricingEngine:
    def __init__(self):
        print("Initializing AI Pricing Engine...")
        
        # 1. Load Government WPI Data (Base Year 2022-23)
        if not os.path.exists("wpi_3 (1).xlsx"):
            raise FileNotFoundError("Critical: wpi_3 (1).xlsx missing in directory.")
        self.wpi_df = pd.read_excel("wpi_3 (1).xlsx", sheet_name="WPI Data")
        
        # 2. Load Internal Tables & Synthetic Retail Data
        try:
            self.pricing_profiles = pd.read_csv("pricing_profile.csv")
            self.buyer_requests = pd.read_csv("buyer_request.csv")
            self.retail_df = pd.read_csv("retail_benchmark.csv")
        except FileNotFoundError as e:
            raise FileNotFoundError(f"Missing a required CSV file: {e}")

        # 3. Train the Random Forest Market Ceiling model
        self.model = self._train_pricing_model(self.retail_df)
        
        # 4. WPI Category Mapping Dictionary
        self.wpi_mapping = {
            "Food processing": "Manufacture Of Food Products",
            "Textile": "Manufacture Of Textiles",
            "Handloom": "Manufacture Of Wearing Apparel",
            "Manufacturing": "Manufacture Of Fabricated Metal Products",
            "Handicraft": "Manufacture Of Wood And Products Of Wood And Cork, Except Furniture; Manufacture Of Articles Of Straw And Plaiting Materials"
        }

    def _train_pricing_model(self, retail_data):
        """Trains the NLP + Random Forest pipeline on retail benchmark data."""
        preprocessor = ColumnTransformer(
            transformers=[
                ('cat', OneHotEncoder(handle_unknown='ignore'), ['Category']),
                ('text', TfidfVectorizer(max_features=100, stop_words='english'), 'Description')
            ])
            
        pipeline = Pipeline([
            ('preprocessor', preprocessor),
            ('regressor', RandomForestRegressor(n_estimators=100, random_state=42))
        ])
        
        pipeline.fit(retail_data[['Category', 'Description']], retail_data['Selling_Price'])
        return pipeline

    def get_wpi_inflation_factor(self, category):
        """Fetches the latest macro-economic index multiplier for the category."""
        wpi_group = self.wpi_mapping.get(category, "Manufacture Of Food Products")
        matched_row = self.wpi_df[self.wpi_df['group'] == wpi_group]
        
        if not matched_row.empty:
            return float(matched_row['index_value'].mean()) / 100.0
        return 1.05  # Fallback multiplier

    def calculate_price_for_product(self, product_id, category, description, is_bulk=False):
        """
        The main calculation function. Feed it strings, it returns a pricing dictionary.
        """
        # Step 1: Find Artisan Cost Profile
        profile_match = self.pricing_profiles[self.pricing_profiles['product_id'] == product_id]
        if profile_match.empty:
            raise ValueError(f"Product ID {product_id} not found in pricing_profile.csv.")
        
        profile = profile_match.iloc[0]
        wpi_multiplier = self.get_wpi_inflation_factor(category)
        
        # Step 2: Cost Floor Calculation
        raw_cost = profile['base_material_cost'] * profile['material_qty'] * wpi_multiplier
        labor_cost = profile['labor_hours_per_unit'] * profile['hourly_wage_inr']
        break_even = raw_cost + labor_cost + profile['packaging_cost_inr']
        desired_floor = break_even * (1 + profile['target_margin_pct'])
        
        # Step 3: Market Ceiling Prediction (Random Forest)
        ml_category = 'Food' if 'Food' in category else 'Handloom' if 'Handloom' in category else 'Manufacturing'
        pred_df = pd.DataFrame([{'Category': ml_category, 'Description': description}])
        market_ceiling = self.model.predict(pred_df)[0]
        
        # Step 4: Check B2B Buyer Requests for Bulk Signals
        open_requests = self.buyer_requests[
            (self.buyer_requests['target_product_id'] == product_id) & 
            (self.buyer_requests['status'] == 'Open')
        ]
        
        # Step 5: Final Pricing Logic
        if is_bulk or not open_requests.empty:
            optimal_price = max(break_even * 1.10, market_ceiling * 0.80)
            pricing_type = "B2B Wholesale Tier (Aggregation Recommended)"
            advice = f"Bulk demand detected. Ensure minimal margin above ₹{break_even:.2f} break-even."
        else:
            optimal_price = min(max(desired_floor, break_even), market_ceiling)
            pricing_type = "B2C Retail Tier"
            advice = f"Break-even floor is ₹{break_even:.2f}. ML predicts market ceiling at ₹{market_ceiling:.2f}."

        return {
            "product_id": product_id,
            "pricing_tier": pricing_type,
            "break_even_floor": round(break_even, 2),
            "recommended_price": round(optimal_price, 2),
            "market_ceiling": round(market_ceiling, 2),
            "ai_guidance": advice
        }

# --- Quick Test Execution ---
if __name__ == "__main__":
    # 1. Instantiate the engine
    engine = VyaparSetuPricingEngine()
    
    # 2. Call the function exactly how your backend will call it
    result = engine.calculate_price_for_product(
        product_id="PROD000010",
        category="Food processing",
        description="Pure handmade organic desi jaggery block no chemicals",
        is_bulk=False
    )
    
    # 3. See the output
    print("\n--- Pricing Output ---")
    for key, value in result.items():
        print(f"{key}: {value}")