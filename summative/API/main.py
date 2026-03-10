import joblib
import numpy as np
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import pandas as pd
import io

# ── App setup ──────────────────────────────────────────────────────────────
app = FastAPI(
    title="Women in STEM Graduation Rate Predictor",
    description="""
    🎯 **Mission:** Empower women in programming by predicting female graduation rates in STEM fields.

    This API predicts the **Female Graduation Rate (%)** based on:
    - Female Enrollment (%)
    - Gender Gap Index
    - STEM Field
    - Year

    Built with ❤️ to support women in tech across Africa.
    """,
    version="1.0.0"
)

# ── CORS Middleware ─────────────────────────────────────────────────────────
# Allows the Flutter app (and any frontend) to call this API from any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # Allow all origins (Flutter app, Swagger UI, etc.)
    allow_credentials=True,
    allow_methods=["*"],       # Allow GET, POST, PUT, DELETE, etc.
    allow_headers=["*"],       # Allow all headers
)

# ── Load model artifacts ────────────────────────────────────────────────────
model         = joblib.load("best_model.pkl")
scaler        = joblib.load("scaler.pkl")
label_encoder = joblib.load("label_encoder.pkl")

# ── Input schema (Pydantic) ─────────────────────────────────────────────────
class PredictionInput(BaseModel):
    female_enrollment: float = Field(
        ...,
        ge=0.0,
        le=100.0,
        description="Female enrollment percentage (0 - 100)"
    )
    gender_gap_index: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Gender Gap Index (0.0 - 1.0)"
    )
    stem_field: str = Field(
        ...,
        description="STEM field: Biology, Engineering, Mathematics, or Physics"
    )
    year: int = Field(
        ...,
        ge=2000,
        le=2030,
        description="Year (2000 - 2030)"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "female_enrollment": 45.0,
                "gender_gap_index": 0.72,
                "stem_field": "Engineering",
                "year": 2022
            }
        }


# ── Output schema ───────────────────────────────────────────────────────────
class PredictionOutput(BaseModel):
    predicted_graduation_rate: float
    message: str


# ── Routes ──────────────────────────────────────────────────────────────────
@app.get("/", tags=["Home"])
def home():
    return {
        "message": "🎯 Women in STEM Graduation Rate Predictor API",
        "docs": "/docs",
        "predict": "/predict"
    }


@app.post("/predict", response_model=PredictionOutput, tags=["Prediction"])
def predict(data: PredictionInput):
    """
    ## Predict Female Graduation Rate

    Provide enrollment, gender gap index, STEM field, and year
    to get a predicted female graduation rate (%).

    **Valid STEM fields:** Biology, Engineering, Mathematics, Physics
    """
    valid_fields = list(label_encoder.classes_)
    if data.stem_field not in valid_fields:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=422,
            detail=f"Invalid stem_field. Choose from: {valid_fields}"
        )

    # Feature engineering (same as training)
    stem_encoded         = label_encoder.transform([data.stem_field])[0]
    enrollment_gendergap = data.female_enrollment * data.gender_gap_index
    years_since_2000     = data.year - 2000

    features = np.array([[
        data.female_enrollment,
        data.gender_gap_index,
        enrollment_gendergap,
        years_since_2000,
        stem_encoded
    ]])

    features_scaled = scaler.transform(features)
    prediction      = model.predict(features_scaled)[0]
    prediction      = round(float(prediction), 2)

    return PredictionOutput(
        predicted_graduation_rate=prediction,
        message=f"Predicted Female Graduation Rate in {data.stem_field} for {data.year}: {prediction}%"
    )


@app.post("/retrain", tags=["Retraining"])
async def retrain(file: UploadFile = File(...)):
    """
    ## Retrain the model with new data

    Upload a CSV file with columns:
    - Female Enrollment (%)
    - Gender Gap Index
    - STEM Fields
    - Year
    - Female Graduation Rate (%)

    The model will retrain automatically on the new data.
    """
    global model, scaler, label_encoder

    contents = await file.read()
    new_df   = pd.read_csv(io.BytesIO(contents))

    required_cols = [
        "Female Enrollment (%)", "Gender Gap Index",
        "STEM Fields", "Year", "Female Graduation Rate (%)"
    ]
    for col in required_cols:
        if col not in new_df.columns:
            from fastapi import HTTPException
            raise HTTPException(
                status_code=400,
                detail=f"Missing column: {col}. Required: {required_cols}"
            )

    # Feature engineering
    from sklearn.preprocessing import LabelEncoder, StandardScaler
    from sklearn.linear_model import LinearRegression

    le_new = LabelEncoder()
    new_df['STEM Fields Encoded'] = le_new.fit_transform(new_df['STEM Fields'])
    new_df['Enrollment_GenderGap'] = new_df['Female Enrollment (%)'] * new_df['Gender Gap Index']
    new_df['Years_Since_2000']     = new_df['Year'] - 2000

    X = new_df[['Female Enrollment (%)', 'Gender Gap Index',
                 'Enrollment_GenderGap', 'Years_Since_2000', 'STEM Fields Encoded']]
    y = new_df['Female Graduation Rate (%)']

    scaler_new = StandardScaler()
    X_scaled   = scaler_new.fit_transform(X)

    new_model = LinearRegression()
    new_model.fit(X_scaled, y)

    # Save updated artifacts
    joblib.dump(new_model,  "best_model.pkl")
    joblib.dump(scaler_new, "scaler.pkl")
    joblib.dump(le_new,     "label_encoder.pkl")

    # Update in memory
    model         = new_model
    scaler        = scaler_new
    label_encoder = le_new

    return {
        "message": f"✅ Model retrained successfully on {len(new_df)} rows!",
        "rows_used": len(new_df)
    }
