from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler

def build_preprocessor():
    numeric = ['Height_in','Weight_lb','Age','Activity_Level']
    passthrough = ['Gender','Goal']
    
    preprocessor = ColumnTransformer([
        ("num", StandardScaler(), numeric), # scales the numeric features/ imports so that larger features dont out weigh
        ("passthrough", "passthrough", passthrough) # passes by features
    ])

    return preprocessor