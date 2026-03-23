import joblib
import numpy as np


def make_prediction(female_enrollment: float,
                    gender_gap_index: float,
                    stem_field: str,
                    year: int) -> float:
    """
    Predicts the Female Graduation Rate (%) given input features.

    Parameters:
        female_enrollment (float): Female enrollment percentage (0-100)
        gender_gap_index  (float): Gender Gap Index (0.0 - 1.0)
        stem_field        (str)  : STEM field — one of:
                                   'Biology', 'Engineering', 'Mathematics', 'Physics'
        year              (int)  : Year (2000 - 2024)

    Returns:
        float: Predicted Female Graduation Rate (%)
    """
    model  = joblib.load('best_model.pkl')
    scaler = joblib.load('scaler.pkl')
    le     = joblib.load('label_encoder.pkl')

    # Encode STEM field
    stem_encoded = le.transform([stem_field])[0]

    # Feature engineering (same transformations applied during training)
    enrollment_gendergap = female_enrollment * gender_gap_index
    years_since_2000     = year - 2000

    # Feature order: [Female Enrollment, Gender Gap Index,
    #                  Enrollment_GenderGap, Years_Since_2000, STEM Fields Encoded]
    features = np.array([[
        female_enrollment,
        gender_gap_index,
        enrollment_gendergap,
        years_since_2000,
        stem_encoded
    ]])

    features_scaled = scaler.transform(features)
    prediction      = model.predict(features_scaled)[0]
    return round(float(prediction), 2)


if __name__ == '__main__':
    result = make_prediction(
        female_enrollment=45.0,
        gender_gap_index=0.72,
        stem_field='Engineering',
        year=2022
    )
    print(f'Predicted Female Graduation Rate: {result}%')
